import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final StorageService _storage =
      StorageService.instance;

  Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> body, {
        bool authenticated = false,
      }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _storage.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    debugPrint('==============================');
    debugPrint('API POST');
    debugPrint('URL: $endpoint');
    debugPrint('BODY: $body');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint(
        'STATUS: ${response.statusCode}',
      );

      debugPrint(
        'RESPONSE: ${response.body}',
      );

      debugPrint('==============================');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('API CONNECTION ERROR: $e');
      debugPrint('==============================');

      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
      String endpoint, {
        bool authenticated = false,
      }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await _storage.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] =
        'Bearer $token';
      }
    }

    debugPrint('==============================');
    debugPrint('API GET');
    debugPrint('URL: $endpoint');

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      );

      debugPrint(
        'STATUS: ${response.statusCode}',
      );

      debugPrint(
        'RESPONSE: ${response.body}',
      );

      debugPrint('==============================');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('API CONNECTION ERROR: $e');
      debugPrint('==============================');

      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(
      String endpoint, {
        bool authenticated = false,
      }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await _storage.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] =
        'Bearer $token';
      }
    }

    final response = await http.delete(
      Uri.parse(endpoint),
      headers: headers,
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(
      http.Response response,
      ) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = {
        'message': response.body,
      };
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'data': decoded,
      };
    }

    if (decoded is Map<String, dynamic>) {
      throw ApiException(
        statusCode: response.statusCode,
        message:
        decoded['message']?.toString() ??
            'Something went wrong.',
        data: decoded,
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: 'Request failed.',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() {
    return message;
  }
}