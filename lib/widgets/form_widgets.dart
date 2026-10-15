import 'package:flutter/material.dart';

import '../core/utils.dart';

class NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool decimal;
  final bool isRequired;

  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.decimal = false,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return isRequired ? 'Введите значение' : null;
        final n = parseNum(s);
        if (n == null) return 'Введите число';
        if (n < 0) return 'Не может быть отрицательным';
        return null;
      },
    );
  }
}

class DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(value),
      ),
    );
  }
}

class ItemMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const ItemMenu({super.key, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Изменить')),
        PopupMenuItem(value: 'delete', child: Text('Удалить')),
      ],
    );
  }
}
