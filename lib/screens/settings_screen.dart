import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();
  bool _saving = false;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final api = await ApiService.getInstance();
    _urlCtrl.text = api.baseUrl;
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = null; });
    try {
      final api = await ApiService.getInstance();
      await api.setBaseUrl(_urlCtrl.text.trim());
      await api.getWeather();
      setState(() {
        _testResult = '✓ Bağlantı başarılı';
        _testSuccess = true;
      });
    } catch (e) {
      setState(() {
        _testResult = '✕ Bağlantı başarısız: $e';
        _testSuccess = false;
      });
    }
    setState(() => _testing = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = await ApiService.getInstance();
      await api.setBaseUrl(_urlCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Ayarlar kaydedildi'),
            backgroundColor: Color(0xFF1A3A1A),
          ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.red));
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = PiDashboardApp.of(context)?.isDark ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Bağlantı ──
          _SectionTitle(title: 'BAĞLANTI'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pi Sunucu URL',
                      style: TextStyle(fontSize: 11, color: AppTheme.mutedDark,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'https://metpi.tail5d616d.ts.net:8000',
                      hintStyle: TextStyle(color: AppTheme.mutedDark, fontSize: 12),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.borderDark),
                      ),
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 8),
                    Text(_testResult!,
                        style: TextStyle(
                            fontSize: 11,
                            color: _testSuccess ? AppTheme.green : AppTheme.red)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _testing ? null : _testConnection,
                          child: _testing
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Test Et'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Kaydet',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Görünüm ──
          _SectionTitle(title: 'GÖRÜNÜM'),
          Card(
            child: Column(
              children: [
                _SettingsRow(
                  icon: isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                  title: 'Karanlık Tema',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => PiDashboardApp.of(context)?.toggleTheme(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Uygulama Hakkında ──
          _SectionTitle(title: 'HAKKINDA'),
          Card(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.info_outline,
                  title: 'Versiyon',
                  trailing: const Text('1.0.0',
                      style: TextStyle(color: AppTheme.mutedDark, fontSize: 12)),
                ),
                _SettingsRow(
                  icon: Icons.code,
                  title: 'GitHub',
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.mutedDark, size: 18),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 10, color: AppTheme.mutedDark, letterSpacing: 1.5)),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  const _SettingsRow({
    required this.icon, required this.title,
    required this.trailing, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.mutedDark),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
            trailing,
          ],
        ),
      ),
    );
  }
}