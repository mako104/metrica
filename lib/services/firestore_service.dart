import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/company.dart';
import '../models/expense.dart';
import '../models/metric.dart';
import '../models/post.dart';
import '../models/task_item.dart';

/// Структура данных:
/// users/{uid}
///   company/profile   — профиль компании
///   posts/{id}        — контент-план
///   metrics/{id}      — маркетинговые показатели
///   expenses/{id}     — расходы
///   tasks/{id}        — задачи
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  static const _timeout = Duration(seconds: 15);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw StateError('Пользователь не авторизован');
    return u.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _userDoc.collection(name);

  Future<void> _save(String col, String id, Map<String, dynamic> data) {
    final ts = FieldValue.serverTimestamp();
    if (id.isEmpty) {
      return _col(col)
          .add({...data, 'createdAt': ts, 'updatedAt': ts}).then((_) {}).timeout(_timeout);
    }
    return _col(col)
        .doc(id)
        .set({...data, 'updatedAt': ts}, SetOptions(merge: true))
        .timeout(_timeout);
  }

  Future<void> _delete(String col, String id) =>
      _col(col).doc(id).delete().timeout(_timeout);

  // ---------- Пользователь ----------
  Future<void> ensureUserDoc(String email) => _userDoc.set(
        {'email': email, 'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      ).timeout(_timeout);

  // ---------- Профиль компании ----------
  DocumentReference<Map<String, dynamic>> get _companyDoc =>
      _col('company').doc('profile');

  Stream<Company?> companyStream() => _companyDoc.snapshots().map(
      (d) => d.exists ? Company.fromMap(d.data() ?? {}) : null);

  Future<Company?> getCompany() async {
    final d = await _companyDoc.get();
    return d.exists ? Company.fromMap(d.data() ?? {}) : null;
  }

  Future<void> saveCompany(Company c) => _companyDoc.set(
        {...c.toMap(), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      ).timeout(_timeout);

  // ---------- Публикации ----------
  Stream<List<Post>> postsStream() => _col('posts')
      .orderBy('date')
      .snapshots()
      .map((s) => s.docs.map(Post.fromDoc).toList());

  Future<void> savePost(Post p) => _save('posts', p.id, p.toMap());
  Future<void> deletePost(String id) => _delete('posts', id);

  // ---------- Показатели ----------
  Stream<List<Metric>> metricsStream() => _col('metrics')
      .orderBy('date')
      .snapshots()
      .map((s) => s.docs.map(Metric.fromDoc).toList());

  Future<void> saveMetric(Metric m) => _save('metrics', m.id, m.toMap());
  Future<void> deleteMetric(String id) => _delete('metrics', id);

  // ---------- Расходы ----------
  Stream<List<Expense>> expensesStream() => _col('expenses')
      .orderBy('date')
      .snapshots()
      .map((s) => s.docs.map(Expense.fromDoc).toList());

  Future<void> saveExpense(Expense e) => _save('expenses', e.id, e.toMap());
  Future<void> deleteExpense(String id) => _delete('expenses', id);

  // ---------- Задачи ----------
  Stream<List<TaskItem>> tasksStream() => _col('tasks')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(TaskItem.fromDoc).toList());

  Future<void> addTask(String title) =>
      _save('tasks', '', {'title': title, 'done': false});

  Future<void> setTaskDone(String id, bool done) =>
      _col('tasks').doc(id).update({'done': done}).timeout(_timeout);

  Future<void> deleteTask(String id) => _delete('tasks', id);
}
