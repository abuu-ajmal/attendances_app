import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
StorageService._();

static final StorageService instance =
StorageService._();

// ============================================================
// ONLINE SESSION
// ============================================================

static const String _tokenKey = 'access_token';
static const String _userKey = 'user';

// ============================================================
// OFFLINE AUTHENTICATION
// ============================================================

static const String _offlineLoginKey =
'offline_login';

static const String _offlinePasswordHashKey =
'offline_password_hash';

static const String _offlineDeviceNameKey =
'offline_device_name';

final FlutterSecureStorage _secureStorage =
const FlutterSecureStorage();

// ============================================================
// TOKEN
// ============================================================

Future<void> saveToken(String token) async {
final prefs =
await SharedPreferences.getInstance();

await prefs.setString(
_tokenKey,
token,
);
}

Future<String?> getToken() async {
final prefs =
await SharedPreferences.getInstance();

return prefs.getString(_tokenKey);
}

// ============================================================
// USER
// ============================================================

Future<void> saveUser(
Map<String, dynamic> user,
) async {
final prefs =
await SharedPreferences.getInstance();

await prefs.setString(
_userKey,
jsonEncode(user),
);
}

Future<Map<String, dynamic>?> getUser() async {
final prefs =
await SharedPreferences.getInstance();

final data =
prefs.getString(_userKey);

if (data == null || data.isEmpty) {
return null;
}

try {
final decoded = jsonDecode(data);

if (decoded is Map<String, dynamic>) {
return decoded;
}

return null;
} catch (_) {
return null;
}
}

// ============================================================
// OFFLINE CREDENTIALS
// ============================================================

Future<void> saveOfflineCredentials({
required String login,
required String passwordHash,
required String deviceName,
}) async {
await _secureStorage.write(
key: _offlineLoginKey,
value: login.trim(),
);

await _secureStorage.write(
key: _offlinePasswordHashKey,
value: passwordHash,
);

await _secureStorage.write(
key: _offlineDeviceNameKey,
value: deviceName,
);
}

Future<String?> getOfflineLogin() async {
return _secureStorage.read(
key: _offlineLoginKey,
);
}

Future<String?> getOfflinePasswordHash() async {
return _secureStorage.read(
key: _offlinePasswordHashKey,
);
}

Future<String?> getOfflineDeviceName() async {
return _secureStorage.read(
key: _offlineDeviceNameKey,
);
}

Future<bool> hasOfflineCredentials() async {
final login =
await getOfflineLogin();

final passwordHash =
await getOfflinePasswordHash();

final user =
await getUser();

return login != null &&
login.trim().isNotEmpty &&
passwordHash != null &&
passwordHash.trim().isNotEmpty &&
user != null;
}

// ============================================================
// CLEAR OFFLINE AUTH
// ============================================================

Future<void> clearOfflineCredentials() async {
await _secureStorage.delete(
key: _offlineLoginKey,
);

await _secureStorage.delete(
key: _offlinePasswordHashKey,
);

await _secureStorage.delete(
key: _offlineDeviceNameKey,
);
}

// ============================================================
// CLEAR CURRENT SESSION
// ============================================================

Future<void> clearSession() async {
final prefs =
await SharedPreferences.getInstance();

await prefs.remove(_tokenKey);
await prefs.remove(_userKey);
}

// ============================================================
// COMPLETE RESET
// ============================================================

Future<void> clear() async {
await clearSession();
await clearOfflineCredentials();
}
}

