import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  Map<String, dynamic>? _storage;
  int _page = 1;
  bool _hasMore = false;
  String _filter = 'all';
  String _sort = 'date_desc';

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; _items = []; });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final api = await ApiService.getInstance();
      if (reset) {
        final storage = await api.getGalleryStorage();
        setState(() => _storage = storage);
      }
      final data = await api.getGallery(
        page: _page, limit: 30,
        type: _filter, sort: _sort,
        refresh: reset,
      );
      setState(() {
        if (reset) {
          _items = data['items'];
        } else {
          _items.addAll(data['items']);
        }
        _hasMore = _page < (data['pages'] as int);
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _loadMore() async {
    _page++;
    await _load();
  }

  Future<void> _upload() async {
    final picker = ImagePicker();
    final files = await picker.pickMultipleMedia();
    if (files.isEmpty) return;

    // İlerleme dialogu göster
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${files.length} dosya yükleniyor…',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );

    try {
      final api = await ApiService.getInstance();
      final paths = files.map((f) => f.path).toList();
      final result = await api.uploadFiles(paths);
      if (mounted) {
        Navigator.pop(context); // dialogu kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${result['uploaded']} dosya yüklendi'),
            backgroundColor: const Color(0xFF1A3A1A),
          ));
        _load(reset: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme hatası: $e'),
              backgroundColor: AppTheme.red));
      }
    }
  }
  Future<void> _delete(String id) async {
    try {
      final api = await ApiService.getInstance();
      await api.deleteGalleryItem(id);
      setState(() => _items.removeWhere((it) => it['id'] == id));
      _loadStorage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.red));
      }
    }
  }

  Future<void> _loadStorage() async {
    try {
      final api = await ApiService.getInstance();
      final s = await api.getGalleryStorage();
      setState(() => _storage = s);
    } catch (_) {}
  }

  String _fmtBytes(int n) {
    if (n >= 1024 * 1024 * 1024) return '${(n / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    if (n >= 1024 * 1024) return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (n >= 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    return '$n B';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _upload,
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppTheme.red),
                          textAlign: TextAlign.center),
                      TextButton(
                          onPressed: () => _load(reset: true),
                          child: const Text('Tekrar Dene')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: () => _load(reset: true),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            children: [
                              // ── Depolama ──
                              if (_storage != null) _StorageCard(storage: _storage!),
                              const SizedBox(height: 12),
                              // ── Filtre ──
                              _FilterRow(
                                filter: _filter,
                                sort: _sort,
                                onFilterChanged: (f) {
                                  setState(() => _filter = f);
                                  _load(reset: true);
                                },
                                onSortChanged: (s) {
                                  setState(() => _sort = s);
                                  _load(reset: true);
                                },
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),

                      // ── Grid ──
                      if (_items.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Text('Henüz fotoğraf/video yok.',
                                style: TextStyle(color: AppTheme.mutedDark)),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _GalleryItem(
                                item: _items[i],
                                onTap: () => _openLightbox(i),
                              ),
                              childCount: _items.length,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                          ),
                        ),

                      // ── Daha Fazla ──
                      if (_hasMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _loadingMore
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : OutlinedButton(
                                    onPressed: _loadMore,
                                    child: const Text('Daha Fazla Yükle'),
                                  ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
    );
  }

  void _openLightbox(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LightboxScreen(
          items: _items,
          initialIndex: index,
          onDelete: _delete,
        ),
      ),
    );
  }
}

// ── Depolama Kartı ────────────────────────────────────
class _StorageCard extends StatelessWidget {
  final Map<String, dynamic> storage;
  const _StorageCard({required this.storage});

  @override
  Widget build(BuildContext context) {
    final pct = (storage['used_pct'] as num).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SSD KULLANIMI',
                    style: TextStyle(fontSize: 10, color: AppTheme.mutedDark,
                        letterSpacing: 1.2)),
                Text('${storage['file_count']} dosya',
                    style: const TextStyle(fontSize: 11, color: AppTheme.mutedDark)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${storage['used_gb']} GB kullanıldı',
                    style: const TextStyle(fontSize: 11, color: AppTheme.mutedDark)),
                Text('%${pct.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.mutedDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filtre Satırı ─────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final String filter;
  final String sort;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;
  const _FilterRow({
    required this.filter, required this.sort,
    required this.onFilterChanged, required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Filtre butonları
        _FilterBtn(label: 'Tümü', value: 'all', current: filter, onTap: onFilterChanged),
        const SizedBox(width: 6),
        _FilterBtn(label: 'Fotoğraf', value: 'image', current: filter, onTap: onFilterChanged),
        const SizedBox(width: 6),
        _FilterBtn(label: 'Video', value: 'video', current: filter, onTap: onFilterChanged),
        const Spacer(),
        // Sıralama
        PopupMenuButton<String>(
          initialValue: sort,
          color: AppTheme.surf2Dark,
          onSelected: onSortChanged,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderDark),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                Icon(Icons.sort, size: 14, color: AppTheme.mutedDark),
                SizedBox(width: 4),
                Text('Sırala', style: TextStyle(fontSize: 11, color: AppTheme.mutedDark)),
              ],
            ),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'date_desc', child: Text('Yeniden Eskiye')),
            const PopupMenuItem(value: 'date_asc',  child: Text('Eskiden Yeniye')),
            const PopupMenuItem(value: 'name_asc',  child: Text('İsim A→Z')),
            const PopupMenuItem(value: 'name_desc', child: Text('İsim Z→A')),
            const PopupMenuItem(value: 'size_desc', child: Text('Büyükten Küçüğe')),
            const PopupMenuItem(value: 'size_asc',  child: Text('Küçükten Büyüğe')),
          ],
        ),
      ],
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label, value, current;
  final ValueChanged<String> onTap;
  const _FilterBtn({required this.label, required this.value,
      required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: active ? cs.primary : AppTheme.borderDark),
          borderRadius: BorderRadius.circular(4),
          color: active ? cs.primary.withOpacity(0.1) : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: active ? cs.primary : AppTheme.mutedDark)),
      ),
    );
  }
}

// ── Grid Item ─────────────────────────────────────────
class _GalleryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _GalleryItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: FutureBuilder<ApiService>(
              future: ApiService.getInstance(),
              builder: (ctx, snap) {
                if (!snap.hasData) return Container(color: AppTheme.surf2Dark);
                return CachedNetworkImage(
                  imageUrl: snap.data!.thumbUrl(item['id']),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.surf2Dark),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surf2Dark,
                    child: const Icon(Icons.broken_image, color: AppTheme.mutedDark),
                  ),
                );
              },
            ),
          ),
          if (item['type'] == 'video')
            Positioned(
              bottom: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('▶ Video',
                    style: TextStyle(fontSize: 9, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Lightbox ──────────────────────────────────────────
class _LightboxScreen extends StatefulWidget {
  final List<dynamic> items;
  final int initialIndex;
  final Future<void> Function(String) onDelete;
  const _LightboxScreen({
    required this.items,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_LightboxScreen> createState() => _LightboxScreenState();
}

class _LightboxScreenState extends State<_LightboxScreen> {
  late int _index;
  late PageController _pageCtrl;
  ApiService? _api;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _index);
    ApiService.getInstance().then((api) => setState(() => _api = api));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _download() async {
  if (_api == null || _downloading) return;
  final item = widget.items[_index];
  setState(() => _downloading = true);
  try {
    final dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) await dir.create(recursive: true);
    final savePath = '${dir.path}/${item['name']}';

    final dio = Dio();
    await dio.download(
      _api!.downloadUrl(item['id']),
      savePath,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Downloads klasörüne indirildi: ${item['name']}'),
          backgroundColor: const Color(0xFF1A3A1A),
        ));
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İndirme hatası: $e'),
            backgroundColor: AppTheme.red));
    }
  }
  setState(() => _downloading = false);
}

  void toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)));
  }

  void _delete() async {
    final item = widget.items[_index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfDark,
        title: const Text('Sil'),
        content: Text('"${item['name']}" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.onDelete(item['id']);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(item['name'],
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis),
        actions: [
          if (_downloading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: _download),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.red),
              onPressed: _delete),
        ],
      ),
      body: _api == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PageView.builder(
                  controller: _pageCtrl,
                  itemCount: widget.items.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (ctx, i) {
                    final it = widget.items[i];
                    if (it['type'] == 'video') {
                      return _VideoPlayer(url: _api!.fileUrl(it['id']));
                    }
                    return InteractiveViewer(
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: _api!.thumbUrl(it['id']),
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const CircularProgressIndicator(),
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white54, size: 64),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      ),
                    ),
                    child: Text(
                      '${item['date']}  ·  ${_index + 1}/${widget.items.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Video Player ──────────────────────────────────────
class _VideoPlayer extends StatefulWidget {
  final String url;
  const _VideoPlayer({required this.url});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _ctrl.play();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
          child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
        });
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: _ctrl.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_ctrl),
              if (!_ctrl.value.isPlaying)
                const Icon(Icons.play_circle_outline,
                    size: 64, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}