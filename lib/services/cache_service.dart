import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _prefix = 'cache_';

  static Future<void> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefix + key, jsonEncode({
      'data': data,
      'time': DateTime.now().toIso8601String(),
    }));
  }

  static Future<Map<String, dynamic>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefix + key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefix + key);
  }

  static String timeAgo(String isoTime) {
    final time = DateTime.parse(isoTime);
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}