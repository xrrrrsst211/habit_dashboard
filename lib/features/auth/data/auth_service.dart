import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authState => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final cleanName = displayName?.trim() ?? '';
    if (cleanName.isNotEmpty) {
      await credential.user?.updateDisplayName(cleanName);
      await credential.user?.reload();
    }

    return credential;
  }

  Future<void> updateDisplayName(String displayName) async {
    final cleanName = displayName.trim();
    if (cleanName.isEmpty) return;

    await _auth.currentUser?.updateDisplayName(cleanName);
    await _auth.currentUser?.reload();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
