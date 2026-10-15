import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/expense.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;
  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.expense?.title);
  late final TextEditingController _amount = TextEditingController(
      text: widget.expense == null
          ? ''
          : widget.expense!.amount.toString().replaceAll(RegExp(r'\.0$'), ''));
  late final TextEditingController _note =
      TextEditingController(text: widget.expense?.note);
  late DateTime _date = widget.expense?.date ?? DateTime.now();
  late String _category = widget.expense?.category ?? kExpenseCategories.first;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirestoreService.instance.saveExpense(Expense(
        id: widget.expense?.id ?? '',
        title: _title.text.trim(),
        category: _category,
        amount: parseNum(_amount.text) ?? 0,
        date: dayOnly(_date),
        note: _note.text.trim(),
      ));
      if (!mounted) return;
      showSnack(context, 'Расход сохранён');
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
          title: Text(widget.expense == null ? 'Новый расход' : 'Редактирование')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: 'Название (например, кампания в VK)'),
                validator: (v) => requiredField(v, 'Введите название'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: [
                  for (final c in kExpenseCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _amount,
                label: 'Сумма ($kCurrency)',
                decimal: true,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              DateField(
                label: 'Дата',
                value: fmtDate(_date),
                onTap: () async {
                  final d = await pickDate(context, _date);
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Заметка'),
              ),
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
