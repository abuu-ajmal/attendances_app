import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  DeviceService._();

  static final DeviceService instance = DeviceService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceName() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      final manufacturer = androidInfo.manufacturer.trim();
      final model = androidInfo.model.trim();

      if (manufacturer.isNotEmpty && model.isNotEmpty) {
        return '$manufacturer $model';
      }

      if (model.isNotEmpty) {
        return model;
      }

      return 'Android Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  Future<String> getPlatform() async {
    return 'Android';
  }

  Future<String> getOsVersion() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      return androidInfo.version.release;
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> getDeviceId() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      return androidInfo.id;
    } catch (e) {
      return 'unknown-device';
    }
  }
}