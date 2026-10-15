import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/utils.dart';
import '../../models/post.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';
import '../../widgets/post_card.dart';

class ContentPlanScreen extends StatefulWidget {
  const ContentPlanScreen({super.key});

  @override
  State<ContentPlanScreen> createState() => _ContentPlanScreenState();
}

class _ContentPlanScreenState extends State<ContentPlanScreen> {
  late final Stream<List<Post>> _posts = FirestoreService.instance.postsStream();
  PostStatus? _filter;

  Future<void> _delete(Post p) async {
    if (!await confirmDialog(context, 'Удалить публикацию «${p.title}»?')) {
      return;
    }
    try {
      await FirestoreService.instance.deletePost(p.id);
      if (p.imagePath != null) await StorageService.instance.delete(p.imagePath!);
      if (mounted) showSnack(context, 'Публикация удалена');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  Widget _chip(String label, PostStatus? value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Контент-план')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.postForm),
        icon: const Icon(Icons.add),
        label: const Text('Публикация'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('Все', null),
                for (final s in PostStatus.values) _chip(s.label, s),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _posts,
              builder: (context, snap) {
                if (snap.hasError) return ErrorView(friendlyError(snap.error!));
                if (!snap.hasData) return const LoadingView();
                final list = snap.data!
                    .where((p) => _filter == null || p.status == _filter)
                    .toList();
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.edit_calendar_outlined,
                      text: 'Публикаций пока нет.\nНажмите «Публикация», чтобы добавить.');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = list[i];
                    return PostCard(
                      post: p,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.postForm,
                          arguments: p),
                      onDelete: () => _delete(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
