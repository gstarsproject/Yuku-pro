import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class YukuApi {
  static const String baseUrl = 'https://mavo-api-preview.gstars-business.workers.dev';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'mavo_access_token';

  // Use Android's normal network DNS resolver. The INTERNET permission
  // is added by the release CI workflow before the APK is built.
  static final http.Client _client = http.Client();

  static Future<Map<String, dynamic>> _decode(http.Response response) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(body['message']?.toString() ?? 'Permintaan gagal (${response.statusCode})');
    }
    return body;
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'displayName': displayName.trim(),
      }),
    ).timeout(const Duration(seconds: 35));
    final data = (await _decode(response))['data'] as Map<String, dynamic>;
    await _storage.write(key: _tokenKey, value: data['accessToken'] as String);
    return data['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    ).timeout(const Duration(seconds: 35));
    final data = (await _decode(response))['data'] as Map<String, dynamic>;
    await _storage.write(key: _tokenKey, value: data['accessToken'] as String);
    return data['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> currentUser() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      await _storage.delete(key: _tokenKey);
      return null;
    }
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      try {
        await _client.post(
          Uri.parse('$baseUrl/api/v1/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));
      } catch (_) {
        // Local credentials are still cleared if the device is offline.
      }
    }
    await _storage.delete(key: _tokenKey);
  }

  static Future<Map<String, dynamic>> health() async {
    final response = await _client.get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw Exception('API tidak merespons (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> categories() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/categories'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw Exception('Kategori gagal dimuat');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> services({
    String query = '',
    String pillar = '',
    String category = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/services').replace(queryParameters: {
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (pillar.isNotEmpty) 'pillar': pillar,
      if (category.isNotEmpty) 'category': category,
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw Exception('Layanan gagal dimuat');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> userProfile(String userId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/users/$userId/profile'),
      headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String displayName, required String bio, String avatarUrl = '',
  }) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.patch(Uri.parse('$baseUrl/api/v1/profile'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'displayName': displayName.trim(), 'bio': bio.trim(), 'avatarUrl': avatarUrl.trim()}))
      .timeout(const Duration(seconds: 25));
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> followStatus(String userId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/users/$userId/follow'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> userRelations(String userId, {required String type}) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final uri = Uri.parse('$baseUrl/api/v1/users/$userId/relations').replace(queryParameters: {'type': type});
    final response = await _client.get(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> setFollow(String userId, {required bool follow}) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final uri = Uri.parse('$baseUrl/api/v1/users/$userId/follow');
    final response = follow
        ? await _client.post(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20))
        : await _client.delete(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadMediaFile({
    required File file, required String mediaType, required String contentType,
  }) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final size = await file.length();
    final prepare = await _client.post(Uri.parse('$baseUrl/api/v1/media/upload-url'),
      headers: {'Content-Type':'application/json','Authorization':'Bearer $token'},
      body: jsonEncode({'mediaType':mediaType,'contentType':contentType,'byteSize':size}))
      .timeout(const Duration(seconds:25));
    final data = (await _decode(prepare))['data'] as Map<String,dynamic>;
    final upload = await _client.put(Uri.parse(data['uploadUrl'] as String),
      headers: {'Content-Type':contentType}, body: await file.readAsBytes())
      .timeout(const Duration(minutes:3));
    if (upload.statusCode < 200 || upload.statusCode >= 300) {
      throw Exception('Upload media gagal (' + upload.statusCode.toString() + ').');
    }
    return {'objectKey':data['objectKey'],'mediaType':mediaType,'contentType':contentType,'byteSize':size};
  }

  static Future<String> mediaDownloadUrl(String mediaId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/media/$mediaId/url'), headers: {'Authorization':'Bearer $token'}).timeout(const Duration(seconds: 20));
    final data = (await _decode(response))['data'] as Map<String,dynamic>;
    return data['downloadUrl'] as String;
  }
  static Future<Map<String, dynamic>> createPost({
    required String content,
    required String audience,
    List<Map<String,dynamic>> media = const [], String locationName = "",
  }) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/posts'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'content': content.trim(), 'audience': audience, 'media':media, if (locationName.trim().isNotEmpty) 'locationName':locationName.trim()}),
    ).timeout(const Duration(seconds: 25));
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> setPostLike(String postId, {required bool liked}) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final uri = Uri.parse('$baseUrl/api/v1/posts/$postId/like');
    final response = liked
        ? await _client.post(uri, headers: {'Authorization': 'Bearer $token'})
        : await _client.delete(uri, headers: {'Authorization': 'Bearer $token'});
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> postComments(String postId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/posts/$postId/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> addPostComment(String postId, String content) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/posts/$postId/comments'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'content': content.trim()}),
    );
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final uri = Uri.parse('$baseUrl/api/v1/users/search').replace(queryParameters: {'q': query.trim()});
    final response = await _client.get(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createConversation(String recipientId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/conversations'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'recipientId': recipientId}),
    ).timeout(const Duration(seconds: 20));
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> conversations() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/conversations'),
      headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    return ((await _decode(response))['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> conversationMessages(String conversationId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/conversations/$conversationId/messages'),
      headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    return ((await _decode(response))['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> sendMessage(String conversationId, String content) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.post(Uri.parse('$baseUrl/api/v1/conversations/$conversationId/messages'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'content': content.trim()})).timeout(const Duration(seconds: 20));
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<void> markConversationRead(String conversationId) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.post(Uri.parse('$baseUrl/api/v1/conversations/$conversationId/read'),
      headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    await _decode(response);
  }

  static Future<List<Map<String, dynamic>>> notifications() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/notifications'),
      headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    return ((await _decode(response))['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<void> markNotificationsRead() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.post(Uri.parse('$baseUrl/api/v1/notifications'),
      headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 20));
    await _decode(response);
  }

  static Future<List<Map<String, dynamic>>> stories() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/stories'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 25));
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createStory({
    required String content,
    required String audience,
    List<Map<String,dynamic>> media = const [], String locationName = "",
  }) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/stories'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'content': content.trim(), 'audience': audience, 'media':media, if (locationName.trim().isNotEmpty) 'locationName':locationName.trim()}),
    ).timeout(const Duration(seconds: 25));
    return (await _decode(response))['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> posts() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Silakan login kembali.');
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/posts'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 25));
    final body = await _decode(response);
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
