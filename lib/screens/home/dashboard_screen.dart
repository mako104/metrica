import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/company.dart';
import '../../models/expense.dart';
import '../../models/metric.dart';
import '../../models/post.dart';
import '../../models/task_item.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/post_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = FirestoreService.instance;
  late final Stream<Company?> _company = _db.companyStream();
  late final Stream<List<Metric>> _metrics = _db.metricsStream();
  late final Stream<List<Expense>> _expenses = _db.expensesStream();
  late final Stream<List<Post>> _posts = _db.postsStream();
  late final Stream<List<TaskItem>> _tasks = _db.tasksStream();

  Future<void> _addTask() async {
    final c = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая задача'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Например: подготовить креативы'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Добавить')),
        ],
      ),
    );
    c.dispose();
    if (title == null || title.isEmpty) return;
    try {
      await _db.addTask(title);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  Widget _header() {
    return StreamBuilder<Company?>(
      stream: _company,
      builder: (context, snap) {
        final n = snap.data?.name ?? '';
        final name = n.isEmpty ? 'Ваша компания' : n;
        return Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Text(name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Главная',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summary() {
    return StreamBuilder<List<Metric>>(
      stream: _metrics,
      builder: (context, ms) {
        if (ms.hasError) return ErrorView(friendlyError(ms.error!));
        if (!ms.hasData) return const LoadingView();
        final from = daysAgo(29);
        final list =
            ms.data!.where((m) => !dayOnly(m.date).isBefore(from)).toList();
        double sum(MetricType t) =>
            list.fold<double>(0, (a, m) => a + m.value(t));
        return StreamBuilder<List<Expense>>(
          stream: _expenses,
          builder: (context, es) {
            final spend =
                (es.data ?? []).fold<double>(0, (a, e) => a + e.amount);
            final cards = <Widget>[
              for (final t in [
                MetricType.reach,
                MetricType.clicks,
                MetricType.followers,
                MetricType.leads,
                MetricType.sales,
              ])
                StatCard(
                    title: t.label,
                    value: t.format(sum(t)),
                    icon: t.icon,
                    color: t.color),
              StatCard(
                  title: 'Расходы на рекламу',
                  value: fmtMoney(spend),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.danger),
            ];
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 74,
              ),
              children: cards,
            );
          },
        );
      },
    );
  }

  Widget _upcoming() {
    return StreamBuilder<List<Post>>(
      stream: _posts,
      builder: (context, snap) {
        if (snap.hasError) return ErrorView(friendlyError(snap.error!));
        if (!snap.hasData) return const LoadingView();
        final now = dayOnly(DateTime.now());
        final list = snap.data!
            .where((p) =>
                p.status != PostStatus.published && !p.date.isBefore(now))
            .take(3)
            .toList();
        if (list.isEmpty) {
          return const AppCard(
              child: EmptyState(
                  icon: Icons.event_available_outlined,
                  text: 'Нет ближайших публикаций'));
        }
        return Column(
          children: [
            for (final p in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PostCard(
                  post: p,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.postForm,
                      arguments: p),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tasksBlock() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: StreamBuilder<List<TaskItem>>(
        stream: _tasks,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(friendlyError(snap.error!));
          if (!snap.hasData) return const LoadingView();
          final active = snap.data!.where((t) => !t.done).toList();
          return Column(
            children: [
              if (active.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Активных задач нет',
                      style: TextStyle(color: AppColors.muted)),
                ),
              for (final t in active)
                CheckboxListTile(
                  value: false,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(t.title),
                  secondary: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _run(() => _db.deleteTask(t.id)),
                  ),
                  onChanged: (_) => _run(() => _db.setTaskDone(t.id, true)),
                ),
              TextButton.icon(
                onPressed: _addTask,
                icon: const Icon(Icons.add),
                label: const Text('Добавить задачу'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _header(),
            const SizedBox(height: 20),
            const SectionTitle('Сводка за 30 дней'),
            _summary(),
            const SizedBox(height: 20),
            const SectionTitle('Ближайшие публикации'),
            _upcoming(),
            const SizedBox(height: 10),
            const SectionTitle('Активные задачи'),
            _tasksBlock(),
          ],
        ),
      ),
    );
  }
}
