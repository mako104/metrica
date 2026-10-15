import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadedImage {
  final String url;
  final String path;
  const UploadedImage(this.url, this.path);
}

/// Хранение изображений: users/{uid}/posts/{время}.jpg
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  Future<UploadedImage> uploadPostImage(File file) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final path =
        'users/$uid/posts/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return UploadedImage(await ref.getDownloadURL(), path);
  }

  Future<void> delete(String path) async {
    try {
      await FirebaseStorage.instance.ref(path).delete();
    } catch (_) {
      // Файла уже нет — это нормально.
    }
  }
}
