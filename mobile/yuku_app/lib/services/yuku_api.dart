import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class YukuApi {
  static const String baseUrl = 'https://mavo-api-preview.gstars-business.workers.dev';
  static const String _apiHost = 'mavo-api-preview.gstars-business.workers.dev';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'mavo_access_token';

  // Resolve the API hostname over HTTPS using a pinned public resolver IP.
  // The API connection still uses the real hostname for TLS certificate
  // verification and the HTTP Host header; no certificate checks are disabled.
  static Future<List<InternetAddress>>? _addressesFuture;
  static int _nextAddress = 0;

  static http.Client _createClient() {
    final nativeClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..findProxy = (uri) { return 'DIRECT'; }
      ..connectionFactory = (uri, proxyHost, proxyPort) async {
        if (uri.host != _apiHost) {
          return Socket.startConnect(uri.host, uri.port);
        }
        final addresses = await _resolveApiAddresses();
        final address = addresses[_nextAddress++ % addresses.length];
        return Socket.startConnect(address, uri.port);
      };
    return IOClient(nativeClient);
  }

  static final http.Client _client = _createClient();

  static Future<List<InternetAddress>> _resolveApiAddresses() {
    return _addressesFuture ??= _lookupWithCloudflare().catchError(
      (Object _) => _lookupWithGoogle(),
    );
  }

  static Future<List<InternetAddress>> _lookupWithCloudflare() {
    return _lookupDoH(
      resolverIp: '1.1.1.1',
      resolverHost: 'cloudflare-dns.com',
      path: '/dns-query',
    );
  }

  static Future<List<InternetAddress>> _lookupWithGoogle() {
    return _lookupDoH(
      resolverIp: '8.8.8.8',
      resolverHost: 'dns.google',
      path: '/resolve',
    );
  }

  static Future<List<InternetAddress>> _lookupDoH({
    required String resolverIp,
    required String resolverHost,
    required String path,
  }) async {
    final dnsClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..findProxy = (uri) { return 'DIRECT'; }
      ..connectionFactory = (uri, proxyHost, proxyPort) {
        return Socket.startConnect(InternetAddress(resolverIp), uri.port);
      };

    try {
      final uri = Uri.https(resolverHost, path, {
        'name': _apiHost,
        'type': 'A',
      });
      final request = await dnsClient.getUrl(uri).timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('DNS resolver returned ${response.statusCode}');
      }
      final payload = jsonDecode(await response.transform(utf8.decoder).join())
          as Map<String, dynamic>;
      final answers = payload['Answer'] as List<dynamic>? ?? const [];
      final addresses = <InternetAddress>[];
      for (final answer in answers) {
        if (answer is Map<String, dynamic> && answer['type'] == 1) {
          final parsed = InternetAddress.tryParse(answer['data']?.toString() ?? '');
          if (parsed != null && parsed.type == InternetAddressType.IPv4) {
            addresses.add(parsed);
          }
        }
      }
      if (addresses.isEmpty) {
        throw const SocketException('No IPv4 address returned by DNS-over-HTTPS');
      }
      return addresses;
    } finally {
      dnsClient.close(force: true);
    }
  }

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
}
