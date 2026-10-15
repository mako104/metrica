import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

const kNetworks = [
  'Instagram',
  'Telegram',
  'VK',
  'TikTok',
  'Facebook',
  'YouTube',
  'LinkedIn',
];

enum PostStatus { planned, inProgress, published }

extension PostStatusX on PostStatus {
  String get label => switch (this) {
        PostStatus.planned => 'Запланировано',
        PostStatus.inProgress => 'В работе',
        PostStatus.published => 'Опубликовано',
      };

  Color get color => switch (this) {
        PostStatus.planned => AppColors.primary,
        PostStatus.inProgress => AppColors.warning,
        PostStatus.published => AppColors.success,
      };

  static PostStatus parse(String? v) => PostStatus.values
      .firstWhere((s) => s.name == v, orElse: () => PostStatus.planned);
}

class Post {
  final String id;
  final String title;
  final String text;
  final DateTime date;
  final String network;
  final PostStatus status;
  final String? imageUrl;
  final String? imagePath;

  const Post({
    required this.id,
    required this.title,
    required this.text,
    required this.date,
    required this.network,
    required this.status,
    this.imageUrl,
    this.imagePath,
  });

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Post(
      id: d.id,
      title: (m['title'] ?? '') as String,
      text: (m['text'] ?? '') as String,
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      network: (m['network'] ?? kNetworks.first) as String,
      status: PostStatusX.parse(m['status'] as String?),
      imageUrl: m['imageUrl'] as String?,
      imagePath: m['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'text': text,
        'date': Timestamp.fromDate(date),
        'network': network,
        'status': status.name,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'tags': <String>[], // задел под будущие ИИ-функции
      };
}
