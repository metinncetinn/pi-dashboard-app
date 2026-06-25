import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  bool _wolLoading = false;
  String? _wolResult;
  bool _wolSuccess = false;

  bool _imgLoading = false;
  String? _imgError;
  String? _imgBase64;
  final _promptCtrl = TextEditingController();

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
      final result = await api.generateImage(prompt);
      setState(() { _imgBase64 = result['image']; });
    } catch (e) {
      setState(() => _imgError = e.toString());
    }
    setState(() => _imgLoading = false);
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
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Wake-on-LAN magic packet gönder',
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.mutedDark)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _wolLoading ? null : _sendWol,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
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
                        style: TextStyle(
                            fontSize: 11,
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
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _promptCtrl,
                    decoration: const InputDecoration(
                      hintText: 'sunset over mountains, digital art',
                      hintStyle: TextStyle(color: AppTheme.mutedDark, fontSize: 12),
                      labelText: 'PROMPT',
                      labelStyle: TextStyle(
                          fontSize: 10, color: AppTheme.mutedDark, letterSpacing: 1.2),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.borderDark),
                      ),
                    ),
                    onSubmitted: (_) => _generateImage(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _imgLoading ? null : _generateImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      child: _imgLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black)),
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
                        style: const TextStyle(fontSize: 11, color: AppTheme.red)),
                  ],
                  if (_imgBase64 != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        Uri.parse('data:image/png;base64,$_imgBase64')
                            .data!.contentAsBytes(),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _saveImage(),
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('İndir'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage() async {
    if (_imgBase64 == null) return;
    try {
      final bytes = Uri.parse('data:image/png;base64,$_imgBase64')
          .data!.contentAsBytes();
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
}