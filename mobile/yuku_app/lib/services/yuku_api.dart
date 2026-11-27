import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class YukuApi {
  static const String baseUrl = 'https://ef0b0e08-yuku-pro.gstars-business.workers.dev';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'mavo_access_token';

  static Future<Map<String, dynamic>> _decode(http.Response response) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Permintaan gagal (${response.statusCode})');
    }
    return body;
  }

  static Future<Map<String, dynamic>> register({required String email, required String password, required String displayName}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password, 'displayName': displayName.trim()}),
    ).timeout(const Duration(seconds: 25));
    final data = (await _decode(response))['data'] as Map<String, dynamic>;
    await _storage.write(key: _tokenKey, value: data['accessToken'] as String);
    return data['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/auth/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    ).timeout(const Duration(seconds: 25));
    final data = (await _decode(response))['data'] as Map<String, dynamic>;
    await _storage.write(key: _tokenKey, value: data['accessToken'] as String);
    return data['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> currentUser() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;
    final response = await http.get(Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode == 401) { await _storage.delete(key: _tokenKey); return null; }
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      try {
        await http.post(Uri.parse('$baseUrl/api/v1/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        // Local credentials are still cleared if the device is offline.
      }
    }
    await _storage.delete(key: _tokenKey);
  }

  static Future<Map<String, dynamic>> health() async {
    final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw Exception('API tidak merespons (${response.statusCode})');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> categories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/categories')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Kategori gagal dimuat');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> services({String query = '', String pillar = '', String category = ''}) async {
    final uri = Uri.parse('$baseUrl/api/v1/services').replace(queryParameters: {
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (pillar.isNotEmpty) 'pillar': pillar,
      if (category.isNotEmpty) 'category': category,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Layanan gagal dimuat');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
