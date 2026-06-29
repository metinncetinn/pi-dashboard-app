import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  // WOL
  bool _wolLoading = false;
  String? _wolResult;
  bool _wolSuccess = false;

  // Resim üretme
  bool _imgLoading = false;
  String? _imgError;
  String? _imgBase64;
  final _promptCtrl = TextEditingController();
  String _selectedStyle = 'none';
  String _selectedSize = '1024x1024';
  List<Map<String, dynamic>> _history = [];

  static const _styles = [
    {'value': 'none',           'label': 'Varsayılan'},
    {'value': 'digital art',    'label': 'Dijital Sanat'},
    {'value': 'photorealistic', 'label': 'Fotoğrafik'},
    {'value': 'anime style',    'label': 'Anime'},
    {'value': 'oil painting',   'label': 'Yağlı Boya'},
    {'value': 'watercolor',     'label': 'Suluboya'},
    {'value': 'pencil sketch',  'label': 'Karakalem'},
    {'value': 'cinematic',      'label': 'Sinematik'},
    {'value': 'minimalist',     'label': 'Minimalist'},
    {'value': '3d render',      'label': '3D Render'},
  ];

  static const _sizes = [
    {'value': '512x512',   'label': '512×512 (Hızlı)'},
    {'value': '768x768',   'label': '768×768'},
    {'value': '1024x1024', 'label': '1024×1024 (Kaliteli)'},
    {'value': '1024x576',  'label': '1024×576 (Geniş)'},
    {'value': '576x1024',  'label': '576×1024 (Dikey)'},
    {'value': '1920x1080',   'label': '1920×1080 (Deneysel HD)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('img_history') ?? [];
    setState(() {
      _history = raw.map((e) => Map<String, dynamic>.from(
        jsonDecode(e) as Map)).toList();
    });
  }

  Future<void> _saveToHistory(String base64, String prompt, String style, String size) async {
    final entry = {
      'base64': base64,
      'prompt': prompt,
      'style': style,
      'size': size,
      'time': DateTime.now().toIso8601String(),
    };
    _history.insert(0, entry);
    if (_history.length > 20) _history = _history.take(20).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('img_history',
        _history.map((e) => jsonEncode(e)).toList());
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Geçmişi Temizle'),
        content: const Text('Tüm geçmiş silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil', style: TextStyle(color: AppTheme.red))),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('img_history');
      setState(() => _history = []);
    }
  }

  Future<void> _sendWol() async {
    setState(() { _wolLoading = true; _wolResult = null; });
    try {
      final api = await ApiService.getInstance();
      await api.sendWol();
      setState(() {
        _wolResult = '✓ Magic packet gönderildi! Bilgisayar yakında açılacak.';
        _wolSuccess = true;
      });
    } catch (e) {
      setState(() {
        _wolResult = '✕ ${e.toString()}';
        _wolSuccess = false;
      });
    }
    setState(() => _wolLoading = false);
  }

  Future<void> _generateImage() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt boş olamaz')));
      return;
    }
    setState(() { _imgLoading = true; _imgError = null; _imgBase64 = null; });
    try {
      final api = await ApiService.getInstance();
      final style = _selectedStyle == 'none' ? '' : _selectedStyle;
      final result = await api.generateImage(prompt, style: style, size: _selectedSize);
      final base64 = result['image'] as String;
      setState(() => _imgBase64 = base64);
      await _saveToHistory(base64, prompt, _selectedStyle, _selectedSize);
    } catch (e) {
      setState(() => _imgError = e.toString());
    }
    setState(() => _imgLoading = false);
  }

  Future<void> _saveImage(String base64) async {
    try {
      final bytes = base64Decode(base64);
      final dir = Directory('/storage/emulated/0/Download');
      final path = '${dir.path}/pi_image_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Downloads klasörüne kaydedildi'),
            backgroundColor: Color(0xFF1A3A1A),
          ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydetme hatası: $e'),
              backgroundColor: AppTheme.red));
      }
    }
  }

  void _openImage(String base64, String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageDetailScreen(
          base64: base64,
          prompt: prompt,
          onSave: () => _saveImage(base64),
          onSendToGallery: () => _saveToGallery(base64, prompt),
        ),
      ),
    );
  }

  Future<void> _saveToGallery(String base64, String prompt) async {
    try {
      // Base64'ü geçici dosyaya yaz
      final dir = Directory.systemTemp;
      final path = '${dir.path}/temp_img_${DateTime.now().millisecondsSinceEpoch}.png';
      final bytes = base64Decode(base64);
      await File(path).writeAsBytes(bytes);

      final api = await ApiService.getInstance();
      await api.uploadFiles([path]);

      // Geçici dosyayı sil
      await File(path).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Galeriye kaydedildi'),
            backgroundColor: Color(0xFF1A3A1A),
          ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Wake on LAN ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💻', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bilgisayarı Aç',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            const Text('Wake-on-LAN magic packet gönder',
                                style: TextStyle(fontSize: 11,
                                    color: AppTheme.mutedDark)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80, height: 38,
                        child: ElevatedButton(
                          onPressed: _wolLoading ? null : _sendWol,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          child: _wolLoading
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Aç',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  if (_wolResult != null) ...[
                    const SizedBox(height: 10),
                    Text(_wolResult!,
                        style: TextStyle(fontSize: 11,
                            color: _wolSuccess ? AppTheme.green : AppTheme.red)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Resim Üretme ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🎨', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Text('Resim Oluştur',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Prompt
                  TextField(
                    controller: _promptCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'sunset over mountains, golden hour...',
                      hintStyle: TextStyle(color: AppTheme.mutedDark,
                          fontSize: 12),
                      labelText: 'PROMPT',
                      labelStyle: TextStyle(fontSize: 10,
                          color: AppTheme.mutedDark, letterSpacing: 1.2),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stil seçimi
                  const Text('STİL',
                      style: TextStyle(fontSize: 10,
                          color: AppTheme.mutedDark, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _styles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final s = _styles[i];
                        final active = _selectedStyle == s['value'];
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedStyle = s['value']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: active ? cs.primary
                                      : AppTheme.borderDark),
                              borderRadius: BorderRadius.circular(20),
                              color: active
                                  ? cs.primary.withOpacity(0.1) : null,
                            ),
                            child: Text(s['label']!,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: active ? cs.primary
                                        : AppTheme.mutedDark)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Boyut seçimi
                  DropdownButtonFormField<String>(
                    value: _selectedSize,
                    decoration: const InputDecoration(
                      labelText: 'BOYUT',
                      labelStyle: TextStyle(fontSize: 10,
                          color: AppTheme.mutedDark, letterSpacing: 1.2),
                    ),
                    items: _sizes.map((s) => DropdownMenuItem(
                      value: s['value'],
                      child: Text(s['label']!,
                          style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedSize = v!),
                  ),
                  const SizedBox(height: 14),

                  // Oluştur butonu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _imgLoading ? null : _generateImage,
                      child: _imgLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black)),
                                SizedBox(width: 10),
                                Text('Oluşturuluyor… (20-40sn)'),
                              ],
                            )
                          : const Text('Oluştur',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),

                  if (_imgError != null) ...[
                    const SizedBox(height: 10),
                    Text(_imgError!,
                        style: const TextStyle(fontSize: 11,
                            color: AppTheme.red)),
                  ],

                  if (_imgBase64 != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _openImage(
                          _imgBase64!, _promptCtrl.text.trim()),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          base64Decode(_imgBase64!),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _saveImage(_imgBase64!),
                            icon: const Icon(Icons.download_outlined, size: 16),
                            label: const Text('İndir'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _saveToGallery(
                                _imgBase64!, _promptCtrl.text.trim()),
                            icon: const Icon(Icons.photo_library_outlined,
                                size: 16),
                            label: const Text('Galeriye Ekle'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Geçmiş ──
          if (_history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GEÇMİŞ',
                    style: TextStyle(fontSize: 10,
                        color: AppTheme.mutedDark, letterSpacing: 1.5)),
                TextButton(
                  onPressed: _clearHistory,
                  child: const Text('Temizle',
                      style: TextStyle(fontSize: 11, color: AppTheme.red)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _history.length,
              itemBuilder: (_, i) {
                final item = _history[i];
                return GestureDetector(
                  onTap: () => _openImage(
                      item['base64'], item['prompt']),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          base64Decode(item['base64']),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent
                              ],
                            ),
                          ),
                          child: Text(
                            item['prompt'],
                            style: const TextStyle(
                                fontSize: 8, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── Resim Detay Ekranı ────────────────────────────────
class _ImageDetailScreen extends StatelessWidget {
  final String base64;
  final String prompt;
  final VoidCallback onSave;
  final VoidCallback onSendToGallery;
  const _ImageDetailScreen({
    required this.base64,
    required this.prompt,
    required this.onSave,
    required this.onSendToGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(prompt,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              onSave();
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Galeriye Ekle',
            onPressed: () {
              onSendToGallery();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.memory(
                  base64Decode(base64),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Prompt göster
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF111111),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROMPT',
                    style: TextStyle(fontSize: 9,
                        color: AppTheme.mutedDark, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(prompt,
                    style: const TextStyle(fontSize: 12,
                        color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}