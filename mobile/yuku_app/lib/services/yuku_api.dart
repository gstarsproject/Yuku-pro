import 'dart:convert';
import 'package:http/http.dart' as http;

class YukuApi {
  static const String baseUrl = 'https://yuku-pro.gstars-business.workers.dev';

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
