import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';

enum MetricType { reach, clicks, followers, leads, sales, revenue }

extension MetricTypeX on MetricType {
  String get label => switch (this) {
        MetricType.reach => 'Охваты',
        MetricType.clicks => 'Клики',
        MetricType.followers => 'Подписчики',
        MetricType.leads => 'Заявки',
        MetricType.sales => 'Продажи',
        MetricType.revenue => 'Доход',
      };

  IconData get icon => switch (this) {
        MetricType.reach => Icons.visibility_outlined,
        MetricType.clicks => Icons.ads_click,
        MetricType.followers => Icons.group_add_outlined,
        MetricType.leads => Icons.assignment_ind_outlined,
        MetricType.sales => Icons.shopping_bag_outlined,
        MetricType.revenue => Icons.payments_outlined,
      };

  Color get color => switch (this) {
        MetricType.reach => AppColors.primary,
        MetricType.clicks => AppColors.secondary,
        MetricType.followers => const Color(0xFFEC4899),
        MetricType.leads => AppColors.warning,
        MetricType.sales => AppColors.success,
        MetricType.revenue => const Color(0xFF0EA5E9),
      };

  String format(double v) =>
      this == MetricType.revenue ? fmtMoney(v) : fmtNumber(v.round());
}

class Metric {
  final String id;
  final DateTime date;
  final int reach;
  final int clicks;
  final int followers;
  final int leads;
  final int sales;
  final double revenue;

  const Metric({
    required this.id,
    required this.date,
    this.reach = 0,
    this.clicks = 0,
    this.followers = 0,
    this.leads = 0,
    this.sales = 0,
    this.revenue = 0,
  });

  double value(MetricType t) => switch (t) {
        MetricType.reach => reach.toDouble(),
        MetricType.clicks => clicks.toDouble(),
        MetricType.followers => followers.toDouble(),
        MetricType.leads => leads.toDouble(),
        MetricType.sales => sales.toDouble(),
        MetricType.revenue => revenue,
      };

  factory Metric.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    int i(String k) => (m[k] as num?)?.toInt() ?? 0;
    return Metric(
      id: d.id,
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reach: i('reach'),
      clicks: i('clicks'),
      followers: i('followers'),
      leads: i('leads'),
      sales: i('sales'),
      revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'reach': reach,
        'clicks': clicks,
        'followers': followers,
        'leads': leads,
        'sales': sales,
        'revenue': revenue,
      };
}
