import 'dart:convert';
import 'package:http/http.dart' as http;

class YukuApi {
  static const String baseUrl = 'https://yuku-pro.gstars-business.workers.dev';
  static String? _accessToken;
  static void setAccessToken(String? token) => _accessToken = token;
  static bool get isSignedIn => _accessToken != null && _accessToken!.isNotEmpty;

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (isSignedIn) 'Authorization': 'Bearer ' + _accessToken!,
  };

  static Future<Map<String, dynamic>> _request(String method, String path, {
    Map<String, dynamic>? body, Map<String, String>? query,
  }) async {
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: query);
    final request = http.Request(method, uri)..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);
    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);
    dynamic decoded;
    try { decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body); }
    catch (_) { throw Exception('Respons server tidak valid (' + response.statusCode.toString() + ')'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message'] : null;
      throw Exception(message?.toString() ?? 'Permintaan gagal (' + response.statusCode.toString() + ')');
    }
    if (decoded is! Map<String, dynamic>) throw Exception('Format respons server tidak valid');
    return decoded;
  }

  static Future<Map<String, dynamic>> register({required String email, required String password, required String displayName, String role = 'CUSTOMER'}) async {
    final result = await _request('POST', '/api/v1/auth/register', body: {'email': email.trim(), 'password': password, 'displayName': displayName.trim(), 'role': role});
    _accessToken = result['accessToken']?.toString();
    return result;
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final result = await _request('POST', '/api/v1/auth/user/login', body: {'email': email.trim(), 'password': password});
    _accessToken = result['accessToken']?.toString();
    return result;
  }

  static void signOut() => _accessToken = null;
  static Future<Map<String, dynamic>> health() => _request('GET', '/health');

  static Future<List<Map<String, dynamic>>> categories() async {
    final result = await _request('GET', '/api/v1/categories');
    final raw = result['items'] ?? result['data'];
    if (raw is! List) throw Exception('Data kategori tidak ditemukan');
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> services({String query = '', String pillar = '', String category = '', String city = ''}) async {
    final result = await _request('GET', '/api/v1/services', query: {
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (pillar.isNotEmpty) 'pillar': pillar,
      if (category.isNotEmpty) 'category': category,
      if (city.isNotEmpty) 'city': city,
    });
    final raw = result['items'] ?? result['data'];
    if (raw is! List) throw Exception('Data layanan tidak ditemukan');
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> myBookings() async {
    final result = await _request('GET', '/api/v1/bookings');
    final raw = result['data'] ?? result['items'] ?? result;
    if (raw is! List) throw Exception('Data booking tidak valid');
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> myProviderServices() async {
    final result = await _request('GET', '/api/v1/provider/me/services');
    final raw = result['data'] ?? result['items'] ?? result;
    if (raw is! List) throw Exception('Data layanan provider tidak valid');
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static Future<Map<String, dynamic>> createProviderService(Map<String, dynamic> service) => _request('POST', '/api/v1/provider/me/services', body: service);
  static Future<Map<String, dynamic>> updateProviderService(String id, Map<String, dynamic> service) => _request('PATCH', '/api/v1/provider/me/services/' + id, body: service);

  static Future<List<Map<String, dynamic>>> myAvailability() async {
    final result = await _request('GET', '/api/v1/provider/me/availability');
    final raw = result['data'] ?? result['items'] ?? result;
    if (raw is! List) throw Exception('Data jadwal provider tidak valid');
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static Future<Map<String, dynamic>> createAvailability({required DateTime startsAt, required DateTime endsAt, bool isBlocked = false}) =>
    _request('POST', '/api/v1/provider/me/availability', body: {'startsAt': startsAt.toUtc().toIso8601String(), 'endsAt': endsAt.toUtc().toIso8601String(), 'isBlocked': isBlocked});

  static Future<void> deleteAvailability(String id) async {
    await _request('DELETE', '/api/v1/provider/me/availability/' + id);
  }
}
