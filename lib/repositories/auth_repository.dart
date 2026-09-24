import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
  AuthRepository({
    ApiService? apiService,
    StorageService? storageService,
    DeviceService? deviceService,
  })  : _apiService = apiService ?? ApiService.instance,
        _storageService =
            storageService ?? StorageService.instance,
        _deviceService =
            deviceService ?? DeviceService.instance;

  final ApiService _apiService;
  final StorageService _storageService;
  final DeviceService _deviceService;

  Future<Map<String, dynamic>> login({
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

    final token = response['token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Login successful but access token was not returned.',
      );
    }

    await _storageService.saveToken(token);

    final user = response['user'];

    if (user is Map<String, dynamic>) {
      await _storageService.saveUser(user);
    }

    return response;
  }

  Future<void> logout() async {
    try {
      await _apiService.post(
        ApiConfig.logout,
        {},
        authenticated: true,
      );
    } finally {
      await _storageService.clear();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();

    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    return _storageService.getUser();
  }
}