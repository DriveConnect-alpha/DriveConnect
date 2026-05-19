import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../calls/relatorio.call.dart';
import '../../../../calls/gerente.call.dart';
import '../../widgets/manager_scaffold.dart';
import '../../../../core/widgets/dc_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _loading = true;
  String? _error;
  List<_ChartPoint> _revenueSeries = const [];
  List<_ChartPoint> _clientsSeries = const [];
  double _totalRevenue = 0;
  int _totalClients = 0;
  int _totalReservations = 0;
  int _monthsWindow = 6;
  bool _showRevenueChart = true;
  bool _showClientsChart = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final now = DateTime.now();
      final months = List<DateTime>.generate(_monthsWindow, (i) {
        final date = DateTime(now.year, now.month - ((_monthsWindow - 1) - i), 1);
        return DateTime(date.year, date.month, 1);
      });

      final revenueData = <_ChartPoint>[];
      double totalRevenue = 0;
      int totalReservations = 0;

      for (final monthStart in months) {
        final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
        final data = await _fetchFaturamento(monthStart, monthEnd);
        final value = (data['faturamentoTotal'] ?? 0).toDouble();
        final qtd = (data['qtdReservas'] ?? 0) as int? ?? 0;
        totalRevenue += value;
        totalReservations += qtd;
        revenueData.add(_ChartPoint(monthStart, value));
      }

      final clientes = await _fetchClientes();
      final clientsSeries = _buildClientSeries(months, clientes);

      if (mounted) {
        setState(() {
          _revenueSeries = revenueData;
          _clientsSeries = clientsSeries;
          _totalRevenue = totalRevenue;
          _totalReservations = totalReservations;
          _totalClients = clientes.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchFaturamento(DateTime start, DateTime end) async {
    final completer = Completer<Map<String, dynamic>>();
    await RelatorioCall.faturamento(
      dataInicio: DateFormat('yyyy-MM-dd').format(start),
      dataFim: DateFormat('yyyy-MM-dd').format(end),
      onSuccess: completer.complete,
      onError: (msg) => completer.completeError(Exception(msg)),
    );
    return completer.future;
  }

  Future<List<Map<String, dynamic>>> _fetchClientes() async {
    final completer = Completer<List<Map<String, dynamic>>>();
    await GerenteCall.listarClientes(
      onSuccess: completer.complete,
      onError: (msg) => completer.completeError(Exception(msg)),
    );
    return completer.future;
  }

  List<_ChartPoint> _buildClientSeries(List<DateTime> months, List<Map<String, dynamic>> clientes) {
    final counts = <String, int>{};
    for (final month in months) {
      final key = _monthKey(month);
      counts[key] = 0;
    }

    for (final cliente in clientes) {
      final createdAt = _parseDate(cliente);
      if (createdAt == null) continue;
      final key = _monthKey(DateTime(createdAt.year, createdAt.month, 1));
      if (counts.containsKey(key)) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    return months
        .map((month) => _ChartPoint(month, (counts[_monthKey(month)] ?? 0).toDouble()))
        .toList();
  }

  String _monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  DateTime? _parseDate(Map<String, dynamic> cliente) {
    final raw = cliente['criado_em'] ??
        cliente['criadoEm'] ??
        cliente['created_at'] ??
        cliente['createdAt'];
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ManagerScaffold(
      title: 'Análises',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar',
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visão analítica',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Receitas e clientes nos últimos 6 meses',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _buildFilters(theme, colorScheme),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.warning, size: 42, color: colorScheme.error),
                        const SizedBox(height: 12),
                        Text('Erro ao carregar dados', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(_error ?? '', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildSummary(theme, colorScheme),
                if (_showRevenueChart) ...[
                  const SizedBox(height: 16),
                  _buildChartCard(
                    title: 'Receita por mês',
                    subtitle: 'Faturamento total por mês',
                    series: _revenueSeries,
                    color: const Color(0xFF2563EB),
                    valuePrefix: 'R\$ ',
                    showSuffixOnAxis: true,
                  ),
                ],
                if (_showClientsChart) ...[
                  const SizedBox(height: 16),
                  _buildChartCard(
                    title: 'Novos clientes por mês',
                    subtitle: 'Clientes cadastrados no período',
                    series: _clientsSeries,
                    color: const Color(0xFF16A34A),
                    valueSuffix: ' clientes',
                    showSuffixOnAxis: false,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtros', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRangeChip('3 meses', 3),
            _buildRangeChip('6 meses', 6),
            _buildRangeChip('12 meses', 12),
            FilterChip(
              label: const Text('Receita'),
              selected: _showRevenueChart,
              onSelected: (value) => setState(() => _showRevenueChart = value),
            ),
            FilterChip(
              label: const Text('Clientes'),
              selected: _showClientsChart,
              onSelected: (value) => setState(() => _showClientsChart = value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeChip(String label, int months) {
    return ChoiceChip(
      label: Text(label),
      selected: _monthsWindow == months,
      onSelected: (selected) {
        if (!selected || _monthsWindow == months) return;
        setState(() => _monthsWindow = months);
        _load();
      },
    );
  }

  Widget _buildSummary(ThemeData theme, ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _summaryCard(
          theme,
          colorScheme,
          title: 'Receita total',
          value: NumberFormat.currency(symbol: 'R\$').format(_totalRevenue),
          icon: Icons.payments,
          accent: const Color(0xFF2563EB),
        ),
        _summaryCard(
          theme,
          colorScheme,
          title: 'Clientes',
          value: _totalClients.toString(),
          icon: Icons.group,
          accent: const Color(0xFF16A34A),
        ),
        _summaryCard(
          theme,
          colorScheme,
          title: 'Reservas',
          value: _totalReservations.toString(),
          icon: Icons.event_available,
          accent: const Color(0xFFF59E0B),
        ),
        _summaryCard(
          theme,
          colorScheme,
          title: 'Média mensal',
          value: NumberFormat.currency(symbol: 'R\$').format(_revenueSeries.isEmpty
              ? 0
              : _totalRevenue / _revenueSeries.length),
          icon: Icons.show_chart,
          accent: const Color(0xFFDB2777),
        ),
      ],
    );
  }

  Widget _summaryCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return DCCard(
      padding: const EdgeInsets.all(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required List<_ChartPoint> series,
    required Color color,
    String? valuePrefix,
    String? valueSuffix,
    bool showSuffixOnAxis = true,
  }) {
    final hasData = series.length >= 2 && series.any((point) => point.value > 0);

    return DCCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: hasData
                ? LineChart(
                    _buildLineData(series, color, valuePrefix, valueSuffix, showSuffixOnAxis),
                  )
                : Center(
                    child: Text(
                      'Sem dados suficientes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineData(
    List<_ChartPoint> series,
    Color color,
    String? valuePrefix,
    String? valueSuffix,
    bool showSuffixOnAxis,
  ) {
    final maxY = series.isEmpty ? 0.0 : series.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;
    final maxX = series.length < 2 ? 1.0 : (series.length - 1).toDouble();
    final bottomInterval = series.length <= 6 ? 1.0 : 2.0;

    return LineChartData(
      minX: 0,
      maxX: maxX,
      minY: minY,
      maxY: maxY == 0 ? 1 : maxY * 1.2,
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: bottomInterval,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= series.length) return const SizedBox.shrink();
              final label = DateFormat('MMM', 'pt_BR').format(series[index].date);
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Transform.rotate(
                    angle: -0.55,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: maxY == 0 ? 1 : maxY / 2,
            getTitlesWidget: (value, meta) {
              final text = _formatCompact(value, valuePrefix, showSuffixOnAxis ? valueSuffix : null);
              return Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: series
              .asMap()
              .entries
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
              .toList(),
          isCurved: true,
          color: color,
          barWidth: 3,
          belowBarData: BarAreaData(show: true, color: color.withOpacity(0.12)),
          dotData: const FlDotData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 12,
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final idx = spot.x.toInt();
              final label = idx >= 0 && idx < series.length
                  ? DateFormat('MMM yyyy', 'pt_BR').format(series[idx].date)
                  : '';
              return LineTooltipItem(
                '$label\n${_formatCompact(spot.y, valuePrefix, valueSuffix)}',
                Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  String _formatCompact(double value, String? prefix, String? suffix) {
    String text;
    if (value >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      text = value.toStringAsFixed(0);
    }
    return '${prefix ?? ''}$text${suffix ?? ''}';
  }
}

class _ChartPoint {
  final DateTime date;
  final double value;

  const _ChartPoint(this.date, this.value);
}
