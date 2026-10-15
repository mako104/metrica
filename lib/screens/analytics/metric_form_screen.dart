import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/metric.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

class MetricFormScreen extends StatefulWidget {
  final Metric? metric;
  const MetricFormScreen({super.key, this.metric});

  @override
  State<MetricFormScreen> createState() => _MetricFormScreenState();
}

class _MetricFormScreenState extends State<MetricFormScreen> {
  final _form = GlobalKey<FormState>();
  late DateTime _date = widget.metric?.date ?? DateTime.now();
  late final Map<MetricType, TextEditingController> _c = {
    for (final t in MetricType.values)
      t: TextEditingController(
          text: widget.metric == null || widget.metric!.value(t) == 0
              ? ''
              : widget.metric!.value(t).toString().replaceAll(RegExp(r'\.0$'), '')),
  };
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(MetricType t) => parseNum(_c[t]!.text) ?? 0;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirestoreService.instance.saveMetric(Metric(
        id: widget.metric?.id ?? '',
        date: dayOnly(_date),
        reach: _v(MetricType.reach).round(),
        clicks: _v(MetricType.clicks).round(),
        followers: _v(MetricType.followers).round(),
        leads: _v(MetricType.leads).round(),
        sales: _v(MetricType.sales).round(),
        revenue: _v(MetricType.revenue),
      ));
      if (!mounted) return;
      showSnack(context, 'Показатели сохранены');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.metric == null ? 'Новые показатели' : 'Редактирование')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DateField(
                label: 'Дата',
                value: fmtDate(_date),
                onTap: () async {
                  final d = await pickDate(context, _date);
                  if (d != null) setState(() => _date = d);
                },
              ),
              for (final t in MetricType.values) ...[
                const SizedBox(height: 12),
                NumberField(
                  controller: _c[t]!,
                  label: t == MetricType.revenue
                      ? 'Доход ($kCurrency)'
                      : t.label,
                  decimal: t == MetricType.revenue,
                ),
              ],
              const SizedBox(height: 24),
              LoadingButton(
                  label: 'Сохранить', loading: _loading, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
