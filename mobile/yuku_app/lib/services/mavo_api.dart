import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MavoApi {
  static const String baseUrl = 'https://mavo-api-preview.gstars-business.workers.dev';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'mavo_access_token';

  static Future<String?> token() => _storage.read(key: _tokenKey);

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final value = await token();
      if (value != null && value.isNotEmpty) headers['Authorization'] = 'Bearer $value';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _decode(http.Response response) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Permintaan gagal (${response.statusCode})');
    }
    return body;
  }

  static Future<Map<String, dynamic>> health() async {
    final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 12));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> login(String email, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/auth/user/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email.trim(), 'password': password}));
    final body = await _decode(response);
    await _storage.write(key: _tokenKey, value: body['data']['accessToken'] as String);
  }

  static Future<void> register(String name, String email, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: await _headers(auth: false),
      body: jsonEncode({'displayName': name.trim(), 'email': email.trim(), 'password': password}));
    final body = await _decode(response);
    await _storage.write(key: _tokenKey, value: body['data']['accessToken'] as String);
  }

  static Future<Map<String, dynamic>> me() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/auth/me'), headers: await _headers());
    final body = await _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  static Future<List<Map<String, dynamic>>> posts({bool followingOnly = false}) async {
    final uri = Uri.parse('$baseUrl/api/v1/posts').replace(queryParameters: followingOnly ? {'following': 'true'} : null);
    final response = await http.get(uri, headers: await _headers())
      .timeout(const Duration(seconds: 20));
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> createPost({required String content, String audience = 'PUBLIC', List<XFile> files = const []}) async {
    final media = <Map<String, dynamic>>[];
    for (final file in files) {
      media.add(await _uploadMedia(file));
    }
    final response = await http.post(Uri.parse('$baseUrl/api/v1/posts'),
      headers: await _headers(),
      body: jsonEncode({'content': content.trim(), 'audience': audience, 'media': media}))
      .timeout(const Duration(seconds: 25));
    final body = await _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map);
  }
  static Future<Map<String, dynamic>> profile(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/users/$userId/profile'),
      headers: await _headers()).timeout(const Duration(seconds: 15));
    final body = await _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String displayName,
    required String bio,
  }) async {
    final response = await http.patch(Uri.parse('$baseUrl/api/v1/profile'),
      headers: await _headers(),
      body: jsonEncode({'displayName': displayName.trim(), 'bio': bio.trim()}))
      .timeout(const Duration(seconds: 20));
    final body = await _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  static Future<List<Map<String, dynamic>>> conversations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/conversations'), headers: await _headers()).timeout(const Duration(seconds: 20));
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/search').replace(queryParameters: {'q': query.trim()});
    final response = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 15));
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<String> createConversation(String recipientId) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/conversations'),
      headers: await _headers(), body: jsonEncode({'recipientId': recipientId})).timeout(const Duration(seconds: 20));
    final body = await _decode(response);
    return body['data']['id'] as String;
  }

  static Future<List<Map<String, dynamic>>> messages(String conversationId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/conversations/$conversationId/messages'),
      headers: await _headers()).timeout(const Duration(seconds: 20));
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> sendMessage(String conversationId, String content) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/conversations/$conversationId/messages'),
      headers: await _headers(), body: jsonEncode({'content': content.trim()})).timeout(const Duration(seconds: 20));
    final body = await _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  static Future<void> markConversationRead(String conversationId) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/conversations/$conversationId/read'),
      headers: await _headers(), body: jsonEncode({})).timeout(const Duration(seconds: 15));
    await _decode(response);
  }

  static Future<void> logout() async {
    try {
      await http.post(Uri.parse('$baseUrl/api/v1/auth/logout'), headers: await _headers());
    } finally {
      await _storage.delete(key: _tokenKey);
    }
  }

  static Future<List<Map<String, dynamic>>> stories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/stories'), headers: await _headers())
      .timeout(const Duration(seconds: 20));
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<String> mediaUrl(String mediaId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/media/$mediaId/url'), headers: await _headers())
      .timeout(const Duration(seconds: 15));
    final body = await _decode(response);
    return body['data']['downloadUrl'] as String;
  }

  static Future<Map<String, dynamic>> _uploadMedia(XFile file) async {
    final path = file.name.toLowerCase();
    final type = file.mimeType?.toLowerCase() ?? '';
    final contentType = type.isNotEmpty ? type : _contentType(path);
    final mediaType = contentType.startsWith('video/') ? 'VIDEO' : 'IMAGE';
    final bytes = await file.readAsBytes();
    final response = await http.post(Uri.parse('$baseUrl/api/v1/media/upload-url'),
      headers: await _headers(),
      body: jsonEncode({'mediaType': mediaType, 'contentType': contentType, 'byteSize': bytes.length}));
    final body = await _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    final uploaded = await http.put(Uri.parse(data['uploadUrl'] as String),
      headers: {'Content-Type': contentType}, body: bytes).timeout(const Duration(minutes: 3));
    if (uploaded.statusCode < 200 || uploaded.statusCode >= 300) {
      throw Exception('File gagal diunggah ke penyimpanan (${uploaded.statusCode}).');
    }
    return {'objectKey': data['objectKey'], 'mediaType': mediaType,
      'contentType': contentType, 'byteSize': bytes.length};
  }

  static String _contentType(String path) {
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.mp4')) return 'video/mp4';
    if (path.endsWith('.mov')) return 'video/quicktime';
    return 'image/jpeg';
  }

  static Future<Map<String, dynamic>> createStory({
    required XFile file,
    String content = '',
    String audience = 'PUBLIC',
  }) async {
    final media = await _uploadMedia(file);
    final response = await http.post(Uri.parse('$baseUrl/api/v1/stories'),
      headers: await _headers(),
      body: jsonEncode({'content': content.trim(), 'audience': audience, 'media': [media]}))
      .timeout(const Duration(seconds: 30));
    final body = await _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map);
  }
}
