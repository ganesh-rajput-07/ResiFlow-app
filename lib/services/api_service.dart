import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String url) async {
    final headers = await _getHeaders();
    return await http.get(Uri.parse(url), headers: headers);
  }

  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> patch(String url, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.patch(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String url) async {
    final headers = await _getHeaders();
    return await http.delete(Uri.parse(url), headers: headers);
  }

  // Token Management
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }
}
