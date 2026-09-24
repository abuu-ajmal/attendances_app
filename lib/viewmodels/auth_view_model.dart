import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    AuthRepository? authRepository,
  }) : _authRepository =
      authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  Future<bool> login({
    required String login,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final response = await _authRepository.login(
        login: login,
        password: password,
      );

      final user = response['user'];

      if (user is Map<String, dynamic>) {
        _user = user;
      }

      _isLoggedIn = true;

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;

      return false;
    } catch (e) {
      _errorMessage =
      'Unable to connect to the server.';

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();

    _user = null;
    _isLoggedIn = false;

    notifyListeners();
  }

  Future<void> loadSession() async {
    final loggedIn =
    await _authRepository.isLoggedIn();

    if (!loggedIn) {
      _isLoggedIn = false;
      return;
    }

    _user =
    await _authRepository.getStoredUser();

    _isLoggedIn = true;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}