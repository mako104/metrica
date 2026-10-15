import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';

/// Вся работа с Firebase Authentication. Пароли хранит только Firebase.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    try {
      await FirestoreService.instance.ensureUserDoc(email);
    } catch (_) {
      // Регистрация уже прошла; документ создастся при первой записи.
    }
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> logout() => _auth.signOut();
}
