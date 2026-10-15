import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/metric.dart';
import '../models/post.dart';
import '../screens/analytics/metric_form_screen.dart';
import '../screens/auth/auth_gate.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_screen.dart';
import '../screens/budget/expense_form_screen.dart';
import '../screens/content_plan/post_form_screen.dart';
import '../screens/home/home_shell.dart';

/// Именованные маршруты (тема курса: Navigator, pushNamed, arguments).
class AppRoutes {
  static const gate = '/';
  static const login = '/login';
  static const register = '/register';
  static const reset = '/reset';
  static const home = '/home';
  static const postForm = '/post-form';
  static const metricForm = '/metric-form';
  static const expenseForm = '/expense-form';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    final Widget page;
    switch (s.name) {
      case login:
        page = const LoginScreen();
        break;
      case register:
        page = const RegisterScreen();
        break;
      case reset:
        page = const ResetScreen();
        break;
      case home:
        page = const HomeShell();
        break;
      case postForm:
        page = PostFormScreen(post: s.arguments as Post?);
        break;
      case metricForm:
        page = MetricFormScreen(metric: s.arguments as Metric?);
        break;
      case expenseForm:
        page = ExpenseFormScreen(expense: s.arguments as Expense?);
        break;
      case gate:
      default:
        page = const AuthGate();
    }
    return MaterialPageRoute(builder: (_) => page, settings: s);
  }
}
