import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<dynamic> _reminders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = await ApiService.getInstance();
      final data = await api.getReminders();
      setState(() { _reminders = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(String id) async {
    try {
      final api = await ApiService.getInstance();
      await api.deleteReminder(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.red));
      }
    }
  }

  Color _badgeColor(Map r) {
    if (r['type'] == 'repeat') return AppTheme.accent2;
    if (r['is_past'] == true) return AppTheme.mutedDark;
    return AppTheme.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
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
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Liste ──
                      Card(
                        child: _reminders.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    'Henüz hatırlatıcı yok.\nAşağıdan oluşturun.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.mutedDark, fontSize: 13),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (int i = 0; i < _reminders.length; i++)
                                    _ReminderRow(
                                      reminder: _reminders[i],
                                      badgeColor: _badgeColor(_reminders[i]),
                                      isLast: i == _reminders.length - 1,
                                      onDelete: () => _delete(_reminders[i]['id_short']),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      // ── Yeni Hatırlatıcı Formu ──
                      _AddReminderCard(onCreated: _load),
                    ],
                  ),
      ),
    );
  }
}

// ── Hatırlatıcı Satırı ────────────────────────────────
class _ReminderRow extends StatelessWidget {
  final Map reminder;
  final Color badgeColor;
  final bool isLast;
  final VoidCallback onDelete;
  const _ReminderRow({
    required this.reminder,
    required this.badgeColor,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = reminder['type'] == 'repeat'
        ? reminder['repeat_label']
        : reminder['fire_str'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(color: AppTheme.borderDark),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder['text'],
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 3),
                Text(timeStr ?? '',
                    style: const TextStyle(fontSize: 11, color: AppTheme.mutedDark)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close, size: 18),
            color: AppTheme.mutedDark,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Yeni Hatırlatıcı Formu ────────────────────────────
class _AddReminderCard extends StatefulWidget {
  final VoidCallback onCreated;
  const _AddReminderCard({required this.onCreated});

  @override
  State<_AddReminderCard> createState() => _AddReminderCardState();
}

class _AddReminderCardState extends State<_AddReminderCard> {
  bool _isRepeat = false;
  bool _loading = false;
  final _textCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  String _repeatType = 'gün';
  int _weekday = 0;
  int _hour = 8;
  int _minute = 0;

  final _weekdays = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];

  Future<void> _create() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj boş olamaz')));
      return;
    }
    setState(() => _loading = true);
    try {
      final api = await ApiService.getInstance();
      Map<String, dynamic> body;
      if (_isRepeat) {
        body = {
          'type': 'repeat',
          'text': text,
          'repeat_type': _repeatType,
          'weekday': _weekday,
          'hour': _hour,
          'minute': _minute,
        };
      } else {
        final t = _timeCtrl.text.trim();
        if (t.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zaman girilmedi')));
          setState(() => _loading = false);
          return;
        }
        body = {'type': 'once', 'text': text, 'fire_at': t};
      }
      await api.createReminder(body);
      _textCtrl.clear();
      _timeCtrl.clear();
      widget.onCreated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Hatırlatıcı oluşturuldu'),
            backgroundColor: Color(0xFF1A3A1A),
          ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.red));
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yeni Hatırlatıcı',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Tekrarlayan toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TEKRARLAYAN',
                    style: TextStyle(fontSize: 10, color: AppTheme.mutedDark,
                        letterSpacing: 1.2)),
                Switch(
                  value: _isRepeat,
                  onChanged: (v) => setState(() => _isRepeat = v),
                  activeColor: cs.primary,
                ),
              ],
            ),
            const Divider(color: AppTheme.borderDark),
            const SizedBox(height: 8),

            // Mesaj
            TextField(
              controller: _textCtrl,
              decoration: const InputDecoration(
                labelText: 'MESAJ',
                labelStyle: TextStyle(fontSize: 10, color: AppTheme.mutedDark,
                    letterSpacing: 1.2),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.borderDark),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bir kerelik
            if (!_isRepeat)
              TextField(
                controller: _timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'ZAMAN',
                  hintText: '14:30  veya  2saat  veya  45dk',
                  hintStyle: TextStyle(color: AppTheme.mutedDark, fontSize: 12),
                  labelStyle: TextStyle(fontSize: 10, color: AppTheme.mutedDark,
                      letterSpacing: 1.2),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.borderDark),
                  ),
                ),
              ),

            // Tekrarlayan
            if (_isRepeat) ...[
              DropdownButtonFormField<String>(
                value: _repeatType,
                dropdownColor: AppTheme.surf2Dark,
                decoration: const InputDecoration(
                  labelText: 'TEKRAR',
                  labelStyle: TextStyle(fontSize: 10, color: AppTheme.mutedDark,
                      letterSpacing: 1.2),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.borderDark),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'gün', child: Text('Her gün')),
                  DropdownMenuItem(value: 'hafta', child: Text('Her hafta')),
                ],
                onChanged: (v) => setState(() => _repeatType = v!),
              ),
              const SizedBox(height: 12),
              if (_repeatType == 'hafta') ...[
                DropdownButtonFormField<int>(
                  value: _weekday,
                  dropdownColor: AppTheme.surf2Dark,
                  decoration: const InputDecoration(
                    labelText: 'GÜN',
                    labelStyle: TextStyle(fontSize: 10, color: AppTheme.mutedDark,
                        letterSpacing: 1.2),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.borderDark),
                    ),
                  ),
                  items: List.generate(7, (i) => DropdownMenuItem(
                    value: i, child: Text(_weekdays[i]))),
                  onChanged: (v) => setState(() => _weekday = v!),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'SAAT',
                        labelStyle: TextStyle(fontSize: 10, color: AppTheme.mutedDark,
                            letterSpacing: 1.2),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.borderDark),
                        ),
                      ),
                      controller: TextEditingController(text: _hour.toString()),
                      onChanged: (v) => _hour = int.tryParse(v) ?? 8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'DAKİKA',
                        labelStyle: TextStyle(fontSize: 10, color: AppTheme.mutedDark,
                            letterSpacing: 1.2),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.borderDark),
                        ),
                      ),
                      controller: TextEditingController(text: _minute.toString()),
                      onChanged: (v) => _minute = int.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Oluştur',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}