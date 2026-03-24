import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseBootstrap {
  static bool initialized = false;

  static Future<void> init() async {
    if (initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      initialized = true;
    } catch (e, s) {
      initialized = false;
      debugPrint('Firebase init failed: $e');
      debugPrintStack(stackTrace: s);
    }
  }
}