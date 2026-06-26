import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  Map<String, dynamic>? _data;
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
      final data = await api.getPortfolio();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmt(double n) {
    return n.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    ).replaceAll('.', 'X').replaceAll(',', '.').replaceAll('X', ',');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                        Text(_error!, style: const TextStyle(color: AppTheme.red), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _load, child: const Text('Tekrar Dene')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Toplam Değer ──
                      _TotalCard(data: _data!),
                      const SizedBox(height: 12),
                      if ((_data!['items'] as List).isNotEmpty)
                        _PortfolioPieChart(items: _data!['items']),
                      const SizedBox(height: 12),
                      // ── Varlıklar ──
                      if ((_data!['items'] as List).isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Portföyünüz boş.\nİşlem Yap butonuyla ekleyin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.mutedDark, fontSize: 13),
                              ),
                            ),
                          ),
                        )
                      else
                        Card(
                          child: Column(
                            children: [
                              for (int i = 0; i < (_data!['items'] as List).length; i++)
                                _AssetRow(
                                  item: _data!['items'][i],
                                  fmt: _fmt,
                                  isLast: i == (_data!['items'] as List).length - 1,
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // ── Kurlar ──
                      Text('ANLIK KURLAR',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.mutedDark,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      _RatesGrid(rates: _data!['rates'], fmt: _fmt),
                      const SizedBox(height: 16),
                      // ── İşlem Yap ──
                      ElevatedButton(
                        onPressed: () => _showTxSheet(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('＋ İşlem Yap',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
      ),
    );
  }

  void _showTxSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TxSheet(onDone: _load),
    );
  }
}

// ── Toplam Kart ───────────────────────────────────────
class _TotalCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TotalCard({required this.data});

  String _fmt(double n) => n.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final pnl    = (data['total_pnl'] as num).toDouble();
    final pnlPct = (data['total_pnl_pct'] as num).toDouble();
    final isPos  = pnl >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TOPLAM DEĞER',
                style: TextStyle(fontSize: 10, color: AppTheme.mutedDark, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(
              '${_fmt((data['total_value'] as num).toDouble())} TL',
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPos ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: isPos ? AppTheme.green : AppTheme.red, size: 18),
                    Text(
                      '${_fmt(pnl.abs())} TL  (${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(2)}%)',
                      style: TextStyle(
                          fontSize: 13, color: isPos ? AppTheme.green : AppTheme.red),
                    ),
                  ],
                ),
                Text(
                  'Maliyet: ${_fmt((data['total_cost'] as num).toDouble())} TL',
                  style: const TextStyle(fontSize: 11, color: AppTheme.mutedDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Varlık Satırı ─────────────────────────────────────
class _AssetRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(double) fmt;
  final bool isLast;
  const _AssetRow({required this.item, required this.fmt, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(color: AppTheme.borderDark, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'],
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${fmt((item['amount'] as num).toDouble())} ${item['symbol']}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.mutedDark)),
                const SizedBox(height: 2),
                Text(
                  'Ort: ${fmt((item['avg_rate'] as num).toDouble())} · Anlık: ${fmt((item['rate'] as num).toDouble())}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF555555)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${fmt((item['value'] as num).toDouble())} TL',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    (item['pnl'] as num) >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: (item['pnl'] as num) >= 0 ? AppTheme.green : AppTheme.red,
                    size: 16,
                  ),
                  Text(
                    '${fmt((item['pnl'] as num).abs().toDouble())} (${(item['pnl_pct'] as num) >= 0 ? '+' : ''}${(item['pnl_pct'] as num).toStringAsFixed(2)}%)',
                    style: TextStyle(
                        fontSize: 11,
                        color: (item['pnl'] as num) >= 0 ? AppTheme.green : AppTheme.red),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Kurlar Grid ───────────────────────────────────────
class _RatesGrid extends StatelessWidget {
  final Map<String, dynamic> rates;
  final String Function(double) fmt;
  const _RatesGrid({required this.rates, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final items = [
      ['usd', 'Dolar'],
      ['eur', 'Euro'],
      ['gram', 'Gram Altın'],
      ['tam', 'Tam Altın'],
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: items.map((e) {
        final val = rates[e[0]];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(e[1],
                    style: const TextStyle(
                        fontSize: 9, color: AppTheme.mutedDark, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  val != null ? '${fmt((val as num).toDouble())} TL' : '—',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── İşlem Sheet ───────────────────────────────────────
class _TxSheet extends StatefulWidget {
  final VoidCallback onDone;
  const _TxSheet({required this.onDone});

  @override
  State<_TxSheet> createState() => _TxSheetState();
}

class _TxSheetState extends State<_TxSheet> {
  bool _isAdd = true;
  String _key = 'usd';
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  final _assets = [
    ['usd', 'Dolar (USD)'],
    ['eur', 'Euro (EUR)'],
    ['gbp', 'Sterlin (GBP)'],
    ['jpy', 'Japon Yeni (JPY)'],
    ['gram', 'Gram Altın'],
    ['ceyrek', 'Çeyrek Altın'],
    ['yarim', 'Yarım Altın'],
    ['tam', 'Tam Altın'],
  ];

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir miktar girin')));
      return;
    }
    setState(() => _loading = true);
    try {
      final api = await ApiService.getInstance();
      if (_isAdd) {
        await api.portfolioAdd(_key, amount);
      } else {
        await api.portfolioRemove(_key, amount);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('İşlem Yap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          // Add/Remove toggle
          Row(
            children: [
              Expanded(
                child: _TabBtn(
                  label: '＋ Ekle',
                  active: _isAdd,
                  activeColor: AppTheme.accent,
                  onTap: () => setState(() => _isAdd = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TabBtn(
                  label: '－ Çıkar',
                  active: !_isAdd,
                  activeColor: AppTheme.red,
                  onTap: () => setState(() => _isAdd = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Varlık seçimi
          DropdownButtonFormField<String>(
            value: _key,
            dropdownColor: AppTheme.surf2Dark,
            decoration: InputDecoration(
              labelText: 'Varlık',
              labelStyle: const TextStyle(color: AppTheme.mutedDark, fontSize: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.borderDark),
              ),
            ),
            items: _assets.map((a) => DropdownMenuItem(
              value: a[0], child: Text(a[1], style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _key = v!),
          ),
          const SizedBox(height: 12),
          // Miktar
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Miktar',
              labelStyle: const TextStyle(color: AppTheme.mutedDark, fontSize: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.borderDark),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isAdd ? 'Ekle' : 'Çıkar',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active,
      required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: active ? activeColor : AppTheme.borderDark),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: active ? activeColor : AppTheme.mutedDark)),
        ),
      ),
    );
  }
}

// ── Pasta Grafiği ─────────────────────────────────────
class _PortfolioPieChart extends StatefulWidget {
  final List<dynamic> items;
  const _PortfolioPieChart({required this.items});

  @override
  State<_PortfolioPieChart> createState() => _PortfolioPieChartState();
}

class _PortfolioPieChartState extends State<_PortfolioPieChart> {
  int _touched = -1;

  static const List<Color> _colors = [
    Color(0xFFC8FF00),
    Color(0xFF00D4FF),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFFF5722),
  ];

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<double>(
        0, (sum, it) => sum + (it['value'] as num).toDouble());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('VARLIK DAĞILIMI',
                style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.mutedDark,
                    letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                // Pasta
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response?.touchedSection == null) {
                              _touched = -1;
                              return;
                            }
                            _touched = response!
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: List.generate(widget.items.length, (i) {
                        final it = widget.items[i];
                        final value = (it['value'] as num).toDouble();
                        final pct = total > 0 ? value / total * 100 : 0;
                        final isTouched = i == _touched;
                        return PieChartSectionData(
                          color: _colors[i % _colors.length],
                          value: value,
                          title: isTouched
                              ? '%${pct.toStringAsFixed(1)}'
                              : '',
                          radius: isTouched ? 52 : 44,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Lejant
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(widget.items.length, (i) {
                      final it = widget.items[i];
                      final value = (it['value'] as num).toDouble();
                      final pct = total > 0 ? value / total * 100 : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: _colors[i % _colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(it['name'],
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text('%${pct.toStringAsFixed(1)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.mutedDark)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}