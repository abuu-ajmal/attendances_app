
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

bool _isOfflineLogin = false;
bool get isOfflineLogin => _isOfflineLogin;

// ============================================================
// OFFLINE CREDENTIALS
// ============================================================

Future<bool> hasOfflineCredentials() async {
return _authRepository.hasOfflineCredentials();
}

// ============================================================
// LOGIN
// ============================================================

Future<bool> login({
required String login,
required String password,
}) async {
_isLoading = true;
_errorMessage = null;

notifyListeners();

try {
final result =
await _authRepository.login(
login: login,
password: password,
);

final storedUser =
result['user'];

if (storedUser is Map<String, dynamic>) {
_user =
Map<String, dynamic>.from(
storedUser,
);
} else {
_user = null;
}

_isLoggedIn = true;

_isOfflineLogin =
result['offline_login'] == true;

return true;
} on ApiException catch (e) {
_errorMessage = e.message;

_isLoggedIn = false;
_isOfflineLogin = false;
_user = null;

return false;
} catch (e) {
_errorMessage =
e.toString().replaceFirst(
'Exception: ',
'',
);

_isLoggedIn = false;
_isOfflineLogin = false;
_user = null;

return false;
} finally {
_isLoading = false;

notifyListeners();
}
}

// ============================================================
// LOGOUT
// ============================================================

Future<void> logout() async {
await _authRepository.logout();

_user = null;
_isLoggedIn = false;
_isOfflineLogin = false;

notifyListeners();
}

// ============================================================
// LOAD SESSION
// ============================================================

  Future<void> loadSession() async {
    try {
      final loggedIn =
      await _authRepository.isLoggedIn();

      if (!loggedIn) {
        _user = null;
        _isLoggedIn = false;
        _isOfflineLogin = false;

        notifyListeners();
        return;
      }

      final storedUser =
      await _authRepository.getStoredUser();

      if (storedUser == null) {
        _user = null;
        _isLoggedIn = false;
        _isOfflineLogin = false;

        notifyListeners();
        return;
      }

      _user = Map<String, dynamic>.from(
        storedUser,
      );

      _isLoggedIn = true;

      final hasOnlineToken =
      await _authRepository.hasOnlineToken();

      _isOfflineLogin = !hasOnlineToken;

      debugPrint(
        'AUTH SESSION => '
            'loggedIn=$_isLoggedIn, '
            'offline=$_isOfflineLogin, '
            'onlineToken=$hasOnlineToken',
      );

      debugPrint(
        'AUTH USER => $_user',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'LOAD SESSION ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _user = null;
      _isLoggedIn = false;
      _isOfflineLogin = false;
    }

    notifyListeners();
  }



// ============================================================
// CLEAR ERROR
// ============================================================

void clearError() {
_errorMessage = null;
notifyListeners();
}
}

