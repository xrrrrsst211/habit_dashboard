import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  static bool initialized = false;

  static Future<void> init() async {
    if (initialized) return;

    try {
      await Firebase.initializeApp();
      initialized = true;
    } catch (e, s) {
      initialized = false;
      debugPrint('Firebase init skipped/failed: $e');
      debugPrintStack(stackTrace: s);
    }
  }
}
