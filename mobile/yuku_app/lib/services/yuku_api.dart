import 'dart:convert';
import 'package:http/http.dart' as http;

class YukuApi {
  static const String baseUrl = 'https://yuku-pro.gstars-business.workers.dev';

  static Future<Map<String, dynamic>> health() async {
    final response = await http
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('API tidak merespons (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
