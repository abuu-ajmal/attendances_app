import 'package:flutter/foundation.dart';

import '../models/attendance_warning.dart';
import '../repositories/notification_repository.dart';

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({
    NotificationRepository? repository,
  }) : _repository =
      repository ?? NotificationRepository();

  final NotificationRepository _repository;

  AttendanceWarning? _warning;

  bool _isLoading = false;
  bool _isOpeningLetter = false;

  String? _errorMessage;
  String? _letterErrorMessage;

  AttendanceWarning? get warning => _warning;

  bool get isLoading => _isLoading;

  bool get isOpeningLetter =>
      _isOpeningLetter;

  String? get errorMessage =>
      _errorMessage;

  String? get letterErrorMessage =>
      _letterErrorMessage;

  bool get hasWarning =>
      _warning?.hasWarning ?? false;

  bool get hasError =>
      _errorMessage != null;

  Future<void> loadNotifications({
    bool showLoader = true,
  }) async {
    if (_isLoading) {
      return;
    }

    if (showLoader) {
      _isLoading = true;
      notifyListeners();
    }

    _errorMessage = null;

    try {
      _warning =
      await _repository.getMyWarning();
    } catch (e) {
      _errorMessage =
          e.toString().replaceFirst(
            'Exception: ',
            '',
          );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadNotifications(
      showLoader: false,
    );
  }

  Future<List<int>> downloadWarningLetter() async {
    if (_isOpeningLetter) {
      throw Exception(
        'Warning letter is already opening.',
      );
    }

    _isOpeningLetter = true;
    _letterErrorMessage = null;

    notifyListeners();

    try {
      final bytes =
      await _repository.getMyWarningLetter();

      if (bytes.isEmpty) {
        throw Exception(
          'Warning letter is empty.',
        );
      }

      return bytes;
    } catch (e) {
      _letterErrorMessage =
          e.toString().replaceFirst(
            'Exception: ',
            '',
          );

      rethrow;
    } finally {
      _isOpeningLetter = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearLetterError() {
    _letterErrorMessage = null;
    notifyListeners();
  }
}