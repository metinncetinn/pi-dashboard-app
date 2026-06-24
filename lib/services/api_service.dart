import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrlKey = 'base_url';
  static const String _defaultUrl = 'https://metpi.tail5d616d.ts.net:8000';

  static ApiService? _instance;
  late Dio _dio;
  String _baseUrl = _defaultUrl;

  ApiService._();

  static Future<ApiService> getInstance() async {
    if (_instance == null) {
      _instance = ApiService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? _defaultUrl;
    _setupDio();
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Geliştirme sırasında self-signed sertifikayı kabul et
    (_dio.httpClientAdapter as dynamic).onHttpClientCreate = (client) {
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  // Base URL'yi güncelle (ayarlar ekranından)
  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
    _baseUrl = url;
    _setupDio();
  }

  String get baseUrl => _baseUrl;

  // ── Portfolio ──────────────────────────────────────
  Future<Map<String, dynamic>> getPortfolio() async {
    final r = await _dio.get('/api/portfolio');
    return r.data;
  }

  Future<Map<String, dynamic>> portfolioAdd(String key, double amount) async {
    final r = await _dio.post('/api/portfolio/add',
        data: {'key': key, 'amount': amount});
    return r.data;
  }

  Future<Map<String, dynamic>> portfolioRemove(String key, double amount) async {
    final r = await _dio.post('/api/portfolio/remove',
        data: {'key': key, 'amount': amount});
    return r.data;
  }

  // ── Weather ───────────────────────────────────────
  Future<Map<String, dynamic>> getWeather() async {
    final r = await _dio.get('/api/weather');
    return r.data;
  }

  // ── Reminders ─────────────────────────────────────
  Future<List<dynamic>> getReminders() async {
    final r = await _dio.get('/api/reminders');
    return r.data;
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> body) async {
    final r = await _dio.post('/api/reminders', data: body);
    return r.data;
  }

  Future<void> deleteReminder(String id) async {
    await _dio.delete('/api/reminders/$id');
  }

  // ── Gallery ───────────────────────────────────────
  Future<Map<String, dynamic>> getGallery({
    int page = 1,
    int limit = 30,
    String type = 'all',
    String sort = 'date_desc',
    bool refresh = false,
  }) async {
    final r = await _dio.get('/api/gallery', queryParameters: {
      'page': page,
      'limit': limit,
      'type': type,
      'sort': sort,
      'refresh': refresh,
    });
    return r.data;
  }

  Future<Map<String, dynamic>> getGalleryStorage() async {
    final r = await _dio.get('/api/gallery/storage');
    return r.data;
  }

  Future<void> deleteGalleryItem(String id) async {
    await _dio.delete('/api/gallery/$id');
  }

  String thumbUrl(String id) => '$_baseUrl/api/gallery/thumb/$id';
  String fileUrl(String id)  => '$_baseUrl/api/gallery/file/$id';
  String downloadUrl(String id) => '$_baseUrl/api/gallery/download/$id';

  // ── WOL ──────────────────────────────────────────
  Future<Map<String, dynamic>> sendWol() async {
    final r = await _dio.post('/api/wol');
    return r.data;
  }

  // ── System ────────────────────────────────────────
  Future<Map<String, dynamic>> getSystemInfo() async {
    final r = await _dio.get('/api/system');
    return r.data;
  }
}