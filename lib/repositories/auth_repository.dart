import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/offline_auth_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
AuthRepository({
ApiService? apiService,
StorageService? storageService,
DeviceService? deviceService,
OfflineAuthService? offlineAuthService,
})  : _apiService =
apiService ?? ApiService.instance,
_storageService =
storageService ?? StorageService.instance,
_deviceService =
deviceService ?? DeviceService.instance,
_offlineAuthService =
offlineAuthService ??
OfflineAuthService.instance;

final ApiService _apiService;
final StorageService _storageService;
final DeviceService _deviceService;
final OfflineAuthService _offlineAuthService;

// ============================================================
// LOGIN
// ============================================================

Future<Map<String, dynamic>> login({
required String login,
required String password,
}) async {
final cleanLogin = login.trim();

if (cleanLogin.isEmpty) {
throw Exception('Login is required.');
}

if (password.isEmpty) {
throw Exception('Password is required.');
}

try {
// --------------------------------------------------------
// 1. TRY ONLINE LOGIN FIRST
// --------------------------------------------------------

return await _loginOnline(
login: cleanLogin,
password: password,
);
} on ApiException catch (e) {
// --------------------------------------------------------
// 2. SERVER / NETWORK UNAVAILABLE
//
// IMPORTANT:
// Do not automatically fallback to offline login for
// authentication errors such as wrong password.
//
// See _isConnectivityError() below.
// --------------------------------------------------------

if (!_isConnectivityError(e)) {
rethrow;
}

return _loginOffline(
login: cleanLogin,
password: password,
);
} catch (e) {
// --------------------------------------------------------
// Other connection exceptions can be handled as offline.
// Authentication exceptions should ideally be represented
// by ApiException in ApiService.
// --------------------------------------------------------

if (_looksLikeNetworkError(e)) {
return _loginOffline(
login: cleanLogin,
password: password,
);
}

rethrow;
}
}

// ============================================================
// ONLINE LOGIN
// ============================================================

Future<Map<String, dynamic>> _loginOnline({
required String login,
required String password,
}) async {
final deviceName =
await _deviceService.getDeviceName();

final response = await _apiService.post(
ApiConfig.login,
{
'login': login,
'password': password,
'device_name': deviceName,
},
);

final token =
response['token']?.toString();

if (token == null || token.isEmpty) {
throw Exception(
'Login successful but access token was not returned.',
);
}

await _storageService.saveToken(token);

final user = response['user'];

if (user is Map<String, dynamic>) {
await _storageService.saveUser(
Map<String, dynamic>.from(user),
);
}

// ----------------------------------------------------------
// Create/update offline password verifier.
//
// We never save the actual password.
// ----------------------------------------------------------

final passwordVerifier =
await _offlineAuthService.createVerifier(
password,
);

await _storageService.saveOfflineCredentials(
login: login,
passwordHash: passwordVerifier,
deviceName: deviceName,
);

return {
...response,
'offline_login': false,
};
}

// ============================================================
// OFFLINE LOGIN
// ============================================================
  Future<bool> hasOnlineToken() async {
    final token = await _storageService.getToken();

    return token != null && token.isNotEmpty;
  }
Future<Map<String, dynamic>> _loginOffline({
required String login,
required String password,
}) async {
final hasCredentials =
await _storageService.hasOfflineCredentials();

if (!hasCredentials) {
throw Exception(
'Offline login is not available. '
'Please connect to the server and login online first.',
);
}

final storedLogin =
await _storageService.getOfflineLogin();

final storedVerifier =
await _storageService.getOfflinePasswordHash();

final storedUser =
await _storageService.getUser();

if (storedLogin == null ||
storedLogin.trim().isEmpty ||
storedVerifier == null ||
storedVerifier.trim().isEmpty ||
storedUser == null) {
throw Exception(
'Offline credentials are incomplete. '
'Please login online first.',
);
}

// ----------------------------------------------------------
// Check login
// ----------------------------------------------------------

if (storedLogin.trim().toLowerCase() !=
login.trim().toLowerCase()) {
throw Exception(
'Invalid login credentials.',
);
}

// ----------------------------------------------------------
// Verify password
// ----------------------------------------------------------

final validPassword =
await _offlineAuthService.verifyPassword(
password: password,
verifier: storedVerifier,
);

if (!validPassword) {
throw Exception(
'Invalid login credentials.',
);
}

// ----------------------------------------------------------
// Offline login does not have an API token.
//
// The stored user is used to build the local session.
// ----------------------------------------------------------

return {
'success': true,
'offline_login': true,
'user': storedUser,
};
}

// ============================================================
// OFFLINE CREDENTIAL CHECK
// ============================================================

Future<bool> hasOfflineCredentials() async {
return _storageService.hasOfflineCredentials();
}

// ============================================================
// LOGOUT
// ============================================================

Future<void> logout() async {
try {
final token =
await _storageService.getToken();

if (token != null && token.isNotEmpty) {
await _apiService.post(
ApiConfig.logout,
{},
authenticated: true,
);
}
} finally {
// --------------------------------------------------------
// IMPORTANT:
//
// Logout only clears the current session.
// Offline credentials remain available.
// --------------------------------------------------------

await _storageService.clearSession();
}
}

// ============================================================
// SESSION
// ============================================================

Future<bool> isLoggedIn() async {
final token =
await _storageService.getToken();

if (token != null && token.isNotEmpty) {
return true;
}

// ----------------------------------------------------------
// Offline session:
// If there is no API token, we can still consider the user
// locally authenticated if offline credentials + user exist.
// ----------------------------------------------------------

return _storageService.hasOfflineCredentials();
}

Future<Map<String, dynamic>?> getStoredUser() async {
return _storageService.getUser();
}

// ============================================================
// NETWORK ERROR DETECTION
// ============================================================

bool _isConnectivityError(ApiException e) {
final message =
e.message.toLowerCase();

return message.contains('socket') ||
message.contains('connection') ||
message.contains('network') ||
message.contains('internet') ||
message.contains('timed out') ||
message.contains('timeout') ||
message.contains('failed host lookup') ||
message.contains('connection refused') ||
message.contains('connection reset');
}

bool _looksLikeNetworkError(Object e) {
final message =
e.toString().toLowerCase();

return message.contains('socketexception') ||
message.contains('failed host lookup') ||
message.contains('connection refused') ||
message.contains('connection reset') ||
message.contains('network is unreachable') ||
message.contains('timed out') ||
message.contains('timeout');
}
}
