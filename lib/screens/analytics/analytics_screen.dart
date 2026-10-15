import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/metric.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final Stream<List<Metric>> _stream =
      FirestoreService.instance.metricsStream();
  int _days = 7;
  MetricType _type = MetricType.reach;

  List<Metric> _inRange(List<Metric> all, DateTime from, DateTime toExcl) =>
      all.where((m) {
        final d = dayOnly(m.date);
        return !d.isBefore(from) && d.isBefore(toExcl);
      }).toList();

  double _sum(List<Metric> l, MetricType t) =>
      l.fold<double>(0, (a, m) => a + m.value(t));

  List<FlSpot> _spots(List<Metric> list, DateTime start) {
    final vals = List<double>.filled(_days, 0);
    for (final m in list) {
      final i = (dayOnly(m.date).difference(start).inHours / 24).round();
      if (i >= 0 && i < _days) vals[i] += m.value(_type);
    }
    return [for (var i = 0; i < _days; i++) FlSpot(i.toDouble(), vals[i])];
  }

  Future<void> _delete(Metric m) async {
    if (!await confirmDialog(context, 'Удалить запись за ${fmtDate(m.date)}?')) {
      return;
    }
    try {
      await FirestoreService.instance.deleteMetric(m.id);
      if (mounted) showSnack(context, 'Запись удалена');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  Widget _chart(List<FlSpot> cur, List<FlSpot> prev, DateTime curStart) {
    const small = TextStyle(fontSize: 10, color: AppColors.muted);
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) =>
                    Text(fmtCompact(v), style: small),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: _days <= 7 ? 1 : (_days / 5).ceilToDouble(),
                getTitlesWidget: (v, meta) {
                  final d = DateTime(
                      curStart.year, curStart.month, curStart.day + v.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('d.MM').format(d), style: small),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: prev,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.muted.withValues(alpha: 0.6),
              barWidth: 2,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: cur,
              isCurved: true,
              preventCurveOverShooting: true,
              color: _type.color,
              barWidth: 3,
              dotData: FlDotData(show: _days <= 7),
              belowBarData:
                  BarAreaData(show: true, color: _type.color.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    Widget dot(Color c, String t) => Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(_type.color, 'Текущий период'),
        const SizedBox(width: 16),
        dot(AppColors.muted.withValues(alpha: 0.6), 'Прошлый период'),
      ],
    );
  }

  Widget _compareRow(MetricType t, double cur, double prev) {
    String change;
    Color color;
    if (prev == 0) {
      change = cur == 0 ? '—' : 'новое';
      color = cur == 0 ? AppColors.muted : AppColors.success;
    } else {
      final p = (cur - prev) / prev * 100;
      change = '${p >= 0 ? '+' : ''}${p.toStringAsFixed(0)}%';
      color = p >= 0 ? AppColors.success : AppColors.danger;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(t.icon, color: t.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Было: ${t.format(prev)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(t.format(cur),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Text(change,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.metricForm),
        icon: const Icon(Icons.add),
        label: const Text('Показатели'),
      ),
      body: StreamBuilder<List<Metric>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(friendlyError(snap.error!));
          if (!snap.hasData) return const LoadingView();

          final curStart = daysAgo(_days - 1);
          final prevStart = daysAgo(_days * 2 - 1);
          final tomorrow = daysAgo(-1);
          final cur = _inRange(snap.data!, curStart, tomorrow);
          final prev = _inRange(snap.data!, prevStart, curStart);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 дней')),
                  ButtonSegment(value: 30, label: Text('30 дней')),
                  ButtonSegment(value: 90, label: Text('90 дней')),
                ],
                selected: {_days},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _days = s.first),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final t in MetricType.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t.label),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    _chart(_spots(cur, curStart), _spots(prev, prevStart),
                        curStart),
                    const SizedBox(height: 12),
                    _legend(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Сравнение с прошлым периодом'),
              for (final t in MetricType.values)
                _compareRow(t, _sum(cur, t), _sum(prev, t)),
              const SizedBox(height: 12),
              const SectionTitle('Записи за период'),
              if (cur.isEmpty)
                const AppCard(
                    child: EmptyState(
                        icon: Icons.bar_chart,
                        text: 'Нет данных за период.\nДобавьте показатели вручную.')),
              for (final m in cur.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fmtDate(m.date),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                'Охваты ${fmtNumber(m.reach)} · Клики ${fmtNumber(m.clicks)} · '
                                'Подписч. ${fmtNumber(m.followers)} · Заявки ${fmtNumber(m.leads)} · '
                                'Продажи ${fmtNumber(m.sales)} · Доход ${fmtMoney(m.revenue)}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        ItemMenu(
                          onEdit: () => Navigator.pushNamed(
                              context, AppRoutes.metricForm,
                              arguments: m),
                          onDelete: () => _delete(m),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
