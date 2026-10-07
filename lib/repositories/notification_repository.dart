import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/attendance_warning.dart';
import '../services/storage_service.dart';

class NotificationRepository {
  NotificationRepository({
    StorageService? storageService,
  }) : _storageService =
      storageService ?? StorageService.instance;

  final StorageService _storageService;

  /// Get current employee attendance warning.
  Future<AttendanceWarning> getMyWarning() async {
    final token = await _storageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found.',
      );
    }

    final uri = Uri.parse(
      ApiConfig.myAttendanceWarning,
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          HttpHeaders.acceptHeader:
          'application/json',
          HttpHeaders.authorizationHeader:
          'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (body is! Map<String, dynamic>) {
          throw Exception(
            'Invalid server response.',
          );
        }

        final data = body['data'];

        if (data is! Map<String, dynamic>) {
          throw Exception(
            'Warning data not found.',
          );
        }

        return AttendanceWarning.fromJson(
          Map<String, dynamic>.from(data),
        );
      }

      if (body is Map &&
          body['message'] != null) {
        throw Exception(
          body['message'].toString(),
        );
      }

      throw Exception(
        'Failed to load attendance warning '
            '(HTTP ${response.statusCode}).',
      );
    } on SocketException {
      throw Exception(
        'Unable to connect to the server.',
      );
    } on FormatException {
      throw Exception(
        'Invalid response received from server.',
      );
    }
  }

  /// Download the official warning letter PDF.
  ///
  /// The endpoint is protected by Sanctum,
  /// therefore the Bearer Token must be sent.
  Future<List<int>> getMyWarningLetter() async {
    final token = await _storageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found.',
      );
    }

    final uri = Uri.parse(
      ApiConfig.myAttendanceWarningLetter,
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          HttpHeaders.acceptHeader:
          'application/pdf',
          HttpHeaders.authorizationHeader:
          'Bearer $token',
        },
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (response.bodyBytes.isEmpty) {
          throw Exception(
            'Warning letter is empty.',
          );
        }

        return response.bodyBytes;
      }

      String message =
          'Failed to load warning letter '
          '(HTTP ${response.statusCode}).';

      try {
        final body = jsonDecode(response.body);

        if (body is Map &&
            body['message'] != null) {
          message =
              body['message'].toString();
        }
      } catch (_) {
        // Response was not JSON.
      }

      throw Exception(message);
    } on SocketException {
      throw Exception(
        'Unable to connect to the server.',
      );
    }
  }
}