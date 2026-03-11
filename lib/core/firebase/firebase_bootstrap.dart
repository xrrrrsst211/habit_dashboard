import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  static bool initialized = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      initialized = true;
    } catch (_) {
      initialized = false;
    }
  }
}