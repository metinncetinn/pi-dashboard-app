import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Her 5 saniyede otomatik yenile
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = await ApiService.getInstance();
      final data = await api.getSystemInfo();
      if (mounted) setState(() { _data = data; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _gaugeColor(double pct) {
    if (pct >= 90) return AppTheme.red;
    if (pct >= 70) return const Color(0xFFFF9800);
    return AppTheme.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      TextButton(onPressed: _load, child: const Text('Tekrar Dene')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Özet kartlar ──
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.4,
                        children: [
                          _GaugeCard(
                            title: 'CPU',
                            value: (_data!['cpu'] as num).toDouble(),
                            subtitle: '%${(_data!['cpu'] as num).toStringAsFixed(1)}',
                            color: _gaugeColor((_data!['cpu'] as num).toDouble()),
                            icon: Icons.memory,
                          ),
                          _GaugeCard(
                            title: 'RAM',
                            value: (_data!['ram_pct'] as num).toDouble(),
                            subtitle: '${_data!['ram_used']} / ${_data!['ram_total']} GB',
                            color: _gaugeColor((_data!['ram_pct'] as num).toDouble()),
                            icon: Icons.storage,
                          ),
                          _GaugeCard(
                            title: 'DISK',
                            value: (_data!['disk_pct'] as num).toDouble(),
                            subtitle: '${_data!['disk_used']} / ${_data!['disk_total']} GB',
                            color: _gaugeColor((_data!['disk_pct'] as num).toDouble()),
                            icon: Icons.disc_full,
                          ),
                          if (_data!['temp'] != null)
                            _GaugeCard(
                              title: 'SICAKLIK',
                              value: (_data!['temp'] as num).toDouble(),
                              maxValue: 85,
                              subtitle: '${(_data!['temp'] as num).toStringAsFixed(1)}°C',
                              color: _gaugeColor(
                                  (_data!['temp'] as num).toDouble() / 85 * 100),
                              icon: Icons.thermostat,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Detay ──
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              _DetailRow(
                                label: 'CPU Kullanımı',
                                value: '%${(_data!['cpu'] as num).toStringAsFixed(1)}',
                                color: _gaugeColor((_data!['cpu'] as num).toDouble()),
                              ),
                              _DetailRow(
                                label: 'RAM Kullanımı',
                                value: '%${(_data!['ram_pct'] as num).toStringAsFixed(1)}',
                                color: _gaugeColor((_data!['ram_pct'] as num).toDouble()),
                              ),
                              _DetailRow(
                                label: 'RAM Kullanılan',
                                value: '${_data!['ram_used']} GB / ${_data!['ram_total']} GB',
                              ),
                              _DetailRow(
                                label: 'Disk Kullanımı',
                                value: '%${(_data!['disk_pct'] as num).toStringAsFixed(1)}',
                                color: _gaugeColor((_data!['disk_pct'] as num).toDouble()),
                              ),
                              _DetailRow(
                                label: 'Disk Kullanılan',
                                value: '${_data!['disk_used']} GB / ${_data!['disk_total']} GB',
                              ),
                              if (_data!['temp'] != null)
                                _DetailRow(
                                  label: 'Pi Sıcaklığı',
                                  value: '${(_data!['temp'] as num).toStringAsFixed(1)}°C',
                                  color: _gaugeColor(
                                      (_data!['temp'] as num).toDouble() / 85 * 100),
                                  isLast: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Her 5 saniyede otomatik yenilenir',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.mutedDark),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Gauge Kart ────────────────────────────────────────
class _GaugeCard extends StatelessWidget {
  final String title;
  final double value;
  final double maxValue;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _GaugeCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.maxValue = 100,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / maxValue).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.mutedDark),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.mutedDark,
                        letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppTheme.borderDark,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Detay Satırı ──────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isLast;
  const _DetailRow({
    required this.label,
    required this.value,
    this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(color: AppTheme.borderDark),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppTheme.mutedDark)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}