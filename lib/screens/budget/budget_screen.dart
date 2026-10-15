import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/expense.dart';
import '../../models/metric.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late final Stream<List<Metric>> _metrics =
      FirestoreService.instance.metricsStream();
  late final Stream<List<Expense>> _expenses =
      FirestoreService.instance.expensesStream();
  int _days = 30; // 0 = за всё время

  Future<void> _delete(Expense e) async {
    if (!await confirmDialog(context, 'Удалить расход «${e.title}»?')) return;
    try {
      await FirestoreService.instance.deleteExpense(e.id);
      if (mounted) showSnack(context, 'Расход удалён');
    } catch (err) {
      if (mounted) showSnack(context, friendlyError(err), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Бюджет')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.expenseForm),
        icon: const Icon(Icons.add),
        label: const Text('Расход'),
      ),
      body: StreamBuilder<List<Metric>>(
        stream: _metrics,
        builder: (context, ms) => StreamBuilder<List<Expense>>(
          stream: _expenses,
          builder: (context, es) {
            if (ms.hasError || es.hasError) {
              return ErrorView(friendlyError((ms.error ?? es.error)!));
            }
            if (!ms.hasData || !es.hasData) return const LoadingView();

            final from = _days == 0 ? null : daysAgo(_days - 1);
            bool inPeriod(DateTime d) =>
                from == null || !dayOnly(d).isBefore(from);

            final exp = es.data!.where((e) => inPeriod(e.date)).toList();
            final revenue = ms.data!
                .where((m) => inPeriod(m.date))
                .fold<double>(0, (a, m) => a + m.revenue);
            final cost = exp.fold<double>(0, (a, e) => a + e.amount);
            final roi = calcRoi(revenue, cost);

            final byCat = <String, double>{};
            for (final e in exp) {
              byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
            }
            final cats = byCat.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 30, label: Text('30 дн')),
                    ButtonSegment(value: 90, label: Text('90 дн')),
                    ButtonSegment(value: 365, label: Text('Год')),
                    ButtonSegment(value: 0, label: Text('Всё')),
                  ],
                  selected: {_days},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _days = s.first),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                          title: 'Общие затраты',
                          value: fmtMoney(cost),
                          icon: Icons.trending_down,
                          color: AppColors.danger),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                          title: 'Доход',
                          value: fmtMoney(revenue),
                          icon: Icons.trending_up,
                          color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ROI',
                          style: TextStyle(color: AppColors.muted)),
                      Text(
                        roi == null ? '—' : '${roi.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: roi == null
                              ? AppColors.muted
                              : (roi >= 0
                                  ? AppColors.success
                                  : AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roi == null
                            ? 'ROI считается, когда есть и затраты, и доход. '
                                'Доход добавляется в разделе «Аналитика».'
                            : 'ROI = (доход − затраты) / затраты × 100%',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionTitle('Расходы по категориям'),
                if (cats.isEmpty)
                  const AppCard(
                      child: EmptyState(
                          icon: Icons.pie_chart_outline,
                          text: 'Расходов за период нет')),
                if (cats.isNotEmpty)
                  AppCard(
                    child: Column(
                      children: [
                        for (final c in cats)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(c.key)),
                                    Text(fmtMoney(c.value),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: cost == 0 ? 0 : c.value / cost,
                                    minHeight: 6,
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                const SectionTitle('Расходы'),
                for (final e in exp.reversed)
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
                                Text(e.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text('${e.category} · ${fmtDate(e.date)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted)),
                              ],
                            ),
                          ),
                          Text(fmtMoney(e.amount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          ItemMenu(
                            onEdit: () => Navigator.pushNamed(
                                context, AppRoutes.expenseForm,
                                arguments: e),
                            onDelete: () => _delete(e),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
