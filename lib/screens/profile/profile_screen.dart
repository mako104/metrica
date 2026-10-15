import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/company.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _industry = TextEditingController();
  final _desc = TextEditingController();
  final _site = TextEditingController();
  final _insta = TextEditingController();
  final _tg = TextEditingController();
  final _vk = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _industry, _desc, _site, _insta, _tg, _vk]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await FirestoreService.instance.getCompany();
      if (c != null) {
        _name.text = c.name;
        _industry.text = c.industry;
        _desc.text = c.description;
        _site.text = c.website;
        _insta.text = c.instagram;
        _tg.text = c.telegram;
        _vk.text = c.vk;
      }
    } catch (e) {
      _loadError = friendlyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirestoreService.instance.saveCompany(Company(
        name: _name.text.trim(),
        industry: _industry.text.trim(),
        description: _desc.text.trim(),
        website: _site.text.trim(),
        instagram: _insta.text.trim(),
        telegram: _tg.text.trim(),
        vk: _vk.text.trim(),
      ));
      if (mounted) showSnack(context, 'Профиль сохранён');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context, 'Выйти из аккаунта?',
        action: 'Выйти');
    if (ok) await AuthService.instance.logout();
  }

  String? _validateSite(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!s.contains('.') || s.contains(' ')) return 'Некорректная ссылка';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль компании'),
        actions: [
          IconButton(
              tooltip: 'Выйти',
              onPressed: _logout,
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : SafeArea(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_loadError!,
                            style: const TextStyle(color: AppColors.danger)),
                      ),
                    Text(email,
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      decoration:
                          const InputDecoration(labelText: 'Название компании'),
                      validator: (v) =>
                          requiredField(v, 'Введите название компании'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _industry,
                      decoration:
                          const InputDecoration(labelText: 'Сфера деятельности'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _desc,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Описание бизнеса'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _site,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                          labelText: 'Сайт', prefixIcon: Icon(Icons.language)),
                      validator: _validateSite,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _insta,
                      decoration: const InputDecoration(
                          labelText: 'Instagram',
                          prefixIcon: Icon(Icons.camera_alt_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tg,
                      decoration: const InputDecoration(
                          labelText: 'Telegram',
                          prefixIcon: Icon(Icons.send_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vk,
                      decoration: const InputDecoration(
                          labelText: 'VK', prefixIcon: Icon(Icons.group_outlined)),
                    ),
                    const SizedBox(height: 20),
                    LoadingButton(
                        label: 'Сохранить', loading: _saving, onPressed: _save),
                  ],
                ),
              ),
            ),
    );
  }
}
