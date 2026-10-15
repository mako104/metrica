import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/post.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

class PostFormScreen extends StatefulWidget {
  final Post? post;
  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.post?.title);
  late final TextEditingController _text =
      TextEditingController(text: widget.post?.text);
  late DateTime _date =
      widget.post?.date ?? DateTime.now().add(const Duration(days: 1));
  late String _network = widget.post?.network ?? kNetworks.first;
  late PostStatus _status = widget.post?.status ?? PostStatus.planned;

  File? _newImage;
  bool _removeImage = false;
  bool _loading = false;

  bool get _isEdit => widget.post != null;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (x != null) {
      setState(() {
        _newImage = File(x.path);
        _removeImage = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final d = await pickDateTime(context, _date);
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? url = widget.post?.imageUrl;
      String? path = widget.post?.imagePath;
      if (_removeImage || _newImage != null) {
        if (path != null) await StorageService.instance.delete(path);
        url = null;
        path = null;
      }
      if (_newImage != null) {
        final up = await StorageService.instance.uploadPostImage(_newImage!);
        url = up.url;
        path = up.path;
      }
      await FirestoreService.instance.savePost(Post(
        id: widget.post?.id ?? '',
        title: _title.text.trim(),
        text: _text.text.trim(),
        date: _date,
        network: _network,
        status: _status,
        imageUrl: url,
        imagePath: path,
      ));
      if (!mounted) return;
      showSnack(context, 'Публикация сохранена');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmDialog(context, 'Удалить эту публикацию?')) return;
    setState(() => _loading = true);
    try {
      await FirestoreService.instance.deletePost(widget.post!.id);
      final path = widget.post!.imagePath;
      if (path != null) await StorageService.instance.delete(path);
      if (!mounted) return;
      showSnack(context, 'Публикация удалена');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _imageBlock() {
    Widget? img;
    if (_newImage != null) {
      img = Image.file(_newImage!, fit: BoxFit.cover);
    } else if (!_removeImage && widget.post?.imageUrl != null) {
      img = Image.network(widget.post!.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image_outlined)));
    }
    if (img == null) {
      return OutlinedButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Добавить изображение'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: 16 / 9, child: img),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: _pickImage),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.danger),
                    onPressed: () => setState(() {
                          _newImage = null;
                          _removeImage = true;
                        })),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактирование' : 'Новая публикация'),
        actions: [
          if (_isEdit)
            IconButton(
                onPressed: _loading ? null : _delete,
                icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) => requiredField(v, 'Введите название'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _text,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Текст публикации'),
              ),
              const SizedBox(height: 12),
              DateField(
                  label: 'Дата и время публикации',
                  value: fmtDateTime(_date),
                  onTap: _pickDate),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _network,
                decoration: const InputDecoration(labelText: 'Социальная сеть'),
                items: [
                  for (final n in kNetworks)
                    DropdownMenuItem(value: n, child: Text(n)),
                ],
                onChanged: (v) => setState(() => _network = v ?? _network),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PostStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Статус'),
                items: [
                  for (final s in PostStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 16),
              _imageBlock(),
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
