import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

/// Символ валюты. Поменяйте на свой (например '₸', '₽', '€').
const kCurrency = r'$';

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Превращает любую ошибку в понятное сообщение на русском.
String friendlyError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'Некорректный email';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'weak-password':
        return 'Слишком простой пароль (минимум 6 символов)';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'network-request-failed':
        return 'Нет подключения к интернету';
      default:
        return 'Ошибка авторизации (${e.code})';
    }
  }
  if (e is TimeoutException) {
    return 'Нет соединения. Данные сохранятся, когда появится интернет';
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return 'Нет доступа. Проверьте правила безопасности Firebase';
    }
    if (e.code == 'unavailable') {
      return 'Сервер недоступен. Проверьте интернет';
    }
    return 'Ошибка Firebase (${e.code})';
  }
  return 'Что-то пошло не так. Попробуйте ещё раз';
}

// ---------- Даты и числа ----------
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Начало дня, который был [n] дней назад (0 = сегодня).
DateTime daysAgo(int n) {
  final t = DateTime.now();
  return DateTime(t.year, t.month, t.day - n);
}

String fmtDate(DateTime d) => DateFormat('d MMM y', 'ru').format(d);
String fmtDateTime(DateTime d) => DateFormat('d MMM, HH:mm', 'ru').format(d);
String fmtNumber(num n) => NumberFormat.decimalPattern('ru').format(n);
String fmtMoney(num n) => '${fmtNumber(n.round())} $kCurrency';
String fmtCompact(num n) => NumberFormat.compact(locale: 'ru').format(n);

double? parseNum(String s) =>
    double.tryParse(s.trim().replaceAll(',', '.').replaceAll(' ', ''));

/// ROI = ((доход - затраты) / затраты) * 100. Если данных нет — null.
double? calcRoi(double revenue, double cost) {
  if (cost <= 0 || revenue <= 0) return null;
  return (revenue - cost) / cost * 100;
}

// ---------- Валидаторы ----------
String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Введите email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
    return 'Некорректный email';
  }
  return null;
}

String? validatePassword(String? v) {
  if ((v ?? '').length < 6) return 'Минимум 6 символов';
  return null;
}

String? requiredField(String? v, [String msg = 'Обязательное поле']) {
  if ((v ?? '').trim().isEmpty) return msg;
  return null;
}

// ---------- Диалоги и выбор даты ----------
Future<bool> confirmDialog(BuildContext context, String text,
    {String action = 'Удалить'}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(text),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action,
                style: const TextStyle(color: AppColors.danger))),
      ],
    ),
  );
  return res ?? false;
}

Future<DateTime?> pickDate(BuildContext context, DateTime initial) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
}

Future<DateTime?> pickDateTime(BuildContext context, DateTime initial) async {
  final d = await pickDate(context, initial);
  if (d == null || !context.mounted) return null;
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  return DateTime(d.year, d.month, d.day, t?.hour ?? initial.hour,
      t?.minute ?? initial.minute);
}
