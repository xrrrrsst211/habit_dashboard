import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileAvatarService {
  static const int maxAvatarBytes = 2 * 1024 * 1024;
  static const String _prefix = 'profile_avatar_base64_';

  static String _key(String uid) => '$_prefix$uid';

  Future<String> getAvatarBase64(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(uid)) ?? '';
  }

  Future<void> saveAvatarBytes(String uid, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(uid), base64Encode(bytes));
  }

  Future<void> removeAvatar(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid));
  }

  Uint8List? decode(String base64Value) {
    final clean = base64Value.trim();
    if (clean.isEmpty) return null;

    try {
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }
}
