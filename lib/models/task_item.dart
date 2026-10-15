import 'package:cloud_firestore/cloud_firestore.dart';

class TaskItem {
  final String id;
  final String title;
  final bool done;

  const TaskItem({required this.id, required this.title, this.done = false});

  factory TaskItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return TaskItem(
      id: d.id,
      title: (m['title'] ?? '') as String,
      done: (m['done'] ?? false) as bool,
    );
  }
}
