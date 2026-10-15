import 'package:cloud_firestore/cloud_firestore.dart';

const kExpenseCategories = [
  'Таргетированная реклама',
  'Контекстная реклама',
  'Блогеры',
  'Контент и дизайн',
  'Инструменты и сервисы',
  'Другое',
];

class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String note;

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory Expense.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Expense(
      id: d.id,
      title: (m['title'] ?? '') as String,
      category: (m['category'] ?? kExpenseCategories.last) as String,
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: (m['note'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'note': note,
      };
}
