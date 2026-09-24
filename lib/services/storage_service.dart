import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userKey,
      jsonEncode(user),
    );
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_userKey);

    if (data == null) {
      return null;
    }

    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}