import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.post(ApiConstants.login, {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _apiService.saveTokens(data['access'], data['refresh']);
        await fetchProfile(); // Fetch profile after login
        return true;
      } else {
        _error = 'Invalid credentials';
        return false;
      }
    } catch (e) {
      _error = 'An error occurred. Please check your connection.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, String> data) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.post(ApiConstants.register, data);
      if (response.statusCode == 201) {
        return true;
      } else {
        final body = jsonDecode(response.body);
        _error = body.toString(); // Shows exactly which field failed from Django
        return false;
      }
    } catch (e) {
      _error = 'Registration failed. Check network connection.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createSociety(Map<String, String> data) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.post(ApiConstants.societies, data);
      if (response.statusCode == 201) {
        // Automatically sync the profile so `user['society']` becomes populated globally.
        await fetchProfile();
        return true;
      } else {
        _error = 'Failed to create society';
        return false;
      }
    } catch (e) {
      _error = 'Network error while creating society';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchProfile() async {
    _setLoading(true);
    try {
      final response = await _apiService.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        _user = jsonDecode(response.body);
        notifyListeners();
      } else {
        await logout(); // Token might be expired/invalid
      }
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tryAutoLogin() async {
    final token = await _apiService.getAccessToken();
    if (token != null) {
      await fetchProfile();
      return _user != null;
    }
    return false;
  }

  Future<void> logout() async {
    await _apiService.clearTokens();
    _user = null;
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> data) {
    _user = data;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
