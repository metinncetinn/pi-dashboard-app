import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  List<String> _cities = [];
  String _selectedCity = '';

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cities = prefs.getStringList('weather_cities') ?? [];
      _selectedCity = prefs.getString('weather_selected') ?? '';
    });
    _load();
  }

  Future<void> _saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('weather_cities', _cities);
    await prefs.setString('weather_selected', _selectedCity);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = await ApiService.getInstance();
      final data = await api.getWeather(city: _selectedCity);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _icon(String code) {
    const icons = {
      '01': '☀️', '02': '⛅', '03': '☁️', '04': '☁️',
      '09': '🌧️', '10': '🌦️', '11': '⛈️', '13': '❄️', '50': '🌫️',
    };
    return icons[code.substring(0, 2)] ?? '🌡️';
  }

  void _showAddCity() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfDark,
        title: const Text('Şehir Ekle'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'İstanbul, Ankara...',
            hintStyle: TextStyle(color: AppTheme.mutedDark),
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Ekle', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    ).then((city) {
      if (city != null && city.trim().isNotEmpty) {
        setState(() {
          if (!_cities.contains(city.trim())) {
            _cities.add(city.trim());
          }
        });
        _saveCities();
      }
    });
  }

  void _showForecast() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ForecastSheet(
        city: _selectedCity,
        iconFn: _icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppTheme.red),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _load, child: const Text('Tekrar Dene')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Şehir seçici ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Varsayılan (Pi konumu)
                            _CityChip(
                              label: 'Varsayılan',
                              selected: _selectedCity.isEmpty,
                              onTap: () {
                                setState(() => _selectedCity = '');
                                _saveCities();
                                _load();
                              },
                            ),
                            // Kayıtlı şehirler
                            for (final city in _cities)
                              _CityChip(
                                label: city,
                                selected: _selectedCity == city,
                                onTap: () {
                                  setState(() => _selectedCity = city);
                                  _saveCities();
                                  _load();
                                },
                                onDelete: () {
                                  setState(() {
                                    _cities.remove(city);
                                    if (_selectedCity == city) _selectedCity = '';
                                  });
                                  _saveCities();
                                  _load();
                                },
                              ),
                            // Ekle butonu
                            GestureDetector(
                              onTap: _showAddCity,
                              child: Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderDark),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add, size: 14, color: AppTheme.mutedDark),
                                    SizedBox(width: 4),
                                    Text('Ekle', style: TextStyle(
                                        fontSize: 12, color: AppTheme.mutedDark)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Ana Kart ──
                      GestureDetector(
                        onTap: _showForecast,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(_icon(_data!['icon']),
                                        style: const TextStyle(fontSize: 64)),
                                    const SizedBox(width: 20),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${_data!['temp']}°C',
                                            style: const TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -1)),
                                        Text(
                                          _data!['city'].toString().toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.mutedDark,
                                              letterSpacing: 1.5),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(_data!['desc'],
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF777777))),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.calendar_month,
                                        size: 13, color: AppTheme.mutedDark),
                                    const SizedBox(width: 4),
                                    const Text('5 günlük tahmin',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.mutedDark)),
                                    const Icon(Icons.chevron_right,
                                        size: 16, color: AppTheme.mutedDark),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Detay Grid (4 kutu) ──
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.4,
                        children: [
                          _DetailCell(label: 'HİSSEDİLEN',
                              value: '${_data!['feels_like']}°C',
                              icon: Icons.thermostat),
                          _DetailCell(label: 'NEM',
                              value: '%${_data!['humidity']}',
                              icon: Icons.water_drop_outlined),
                          _DetailCell(label: 'RÜZGAR',
                              value: '${_data!['wind']} km/h',
                              icon: Icons.air),
                          _DetailCell(label: 'YAĞMUR',
                              value: '%${_data!['rain_pct'] ?? 0}',
                              icon: Icons.umbrella_outlined),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}

// ── Şehir Chip ────────────────────────────────────────
class _CityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _CityChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: EdgeInsets.fromLTRB(12, 6, onDelete != null ? 4 : 12, 6),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? accentColor : AppTheme.borderDark),
          borderRadius: BorderRadius.circular(20),
          color: selected ? accentColor.withOpacity(0.1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? accentColor : AppTheme.mutedDark)),
            if (onDelete != null) ...[
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 14,
                    color: AppTheme.mutedDark),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Detay Kutu ────────────────────────────────────────
class _DetailCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DetailCell({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.mutedDark),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.mutedDark,
                        letterSpacing: 1.2)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 5 Günlük Tahmin Sheet ─────────────────────────────
class _ForecastSheet extends StatefulWidget {
  final String city;
  final String Function(String) iconFn;
  const _ForecastSheet({required this.city, required this.iconFn});

  @override
  State<_ForecastSheet> createState() => _ForecastSheetState();
}

class _ForecastSheetState extends State<_ForecastSheet> {
  List<dynamic>? _forecast;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = await ApiService.getInstance();
      final data = await api.getWeatherForecast(city: widget.city);
      setState(() { _forecast = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _dayName(String date) {
    final d = DateTime.parse(date);
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final today = DateTime.now();
    if (d.day == today.day) return 'Bugün';
    if (d.day == today.day + 1) return 'Yarın';
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('5 Günlük Tahmin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          else if (_error != null)
            Center(child: Text(_error!, style: const TextStyle(color: AppTheme.red)))
          else
            for (final day in _forecast!)
              _ForecastRow(day: day, dayName: _dayName(day['date']), iconFn: widget.iconFn),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final Map<String, dynamic> day;
  final String dayName;
  final String Function(String) iconFn;
  const _ForecastRow({required this.day, required this.dayName, required this.iconFn});

  @override
  Widget build(BuildContext context) {
    final morning = day['morning'];
    final evening = day['evening'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
      ),
      child: Row(
        children: [
          // Gün adı
          SizedBox(
            width: 52,
            child: Text(dayName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          // İkon
          Text(iconFn(day['icon']), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          // Min/Max
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${day['min_temp']}° / ${day['max_temp']}°',
                  style: const TextStyle(fontSize: 13)),
              Text('%${day['rain_pct']} yağmur',
                  style: const TextStyle(fontSize: 10, color: AppTheme.mutedDark)),
            ],
          ),
          const Spacer(),
          // Sabah / Akşam
          if (morning != null)
            _TimeTemp(
              time: '☀️ Sabah',
              temp: '${morning['temp']}°',
              icon: iconFn(morning['icon']),
            ),
          const SizedBox(width: 10),
          if (evening != null)
            _TimeTemp(
              time: '🌙 Akşam',
              temp: '${evening['temp']}°',
              icon: iconFn(evening['icon']),
            ),
        ],
      ),
    );
  }
}

class _TimeTemp extends StatelessWidget {
  final String time;
  final String temp;
  final String icon;
  const _TimeTemp({required this.time, required this.temp, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        Text(temp, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(time, style: const TextStyle(fontSize: 9, color: AppTheme.mutedDark)),
      ],
    );
  }
}