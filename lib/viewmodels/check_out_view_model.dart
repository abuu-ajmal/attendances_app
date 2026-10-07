import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/device_service.dart';

import '../models/attendance.dart';
import '../repositories/attendance_repository.dart';
import '../services/storage_service.dart';

class CheckOutViewModel extends ChangeNotifier {
  CheckOutViewModel({
    AttendanceRepository? attendanceRepository,
    StorageService? storageService,
    DeviceService? deviceService,
  })  : _attendanceRepository =
      attendanceRepository ??
          AttendanceRepository(),
        _storageService =
            storageService ??
                StorageService.instance,
        _deviceService =
            deviceService ??
                DeviceService.instance;

  final AttendanceRepository _attendanceRepository;

  final StorageService _storageService;

  final DeviceService _deviceService;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Attendance? _attendance;

  Attendance? get attendance => _attendance;

  // ============================================================
  // GET EMPLOYEE ID
  // ============================================================

  Future<int?> _getEmployeeId() async {
    try {
      final user =
      await _storageService.getUser();

      if (user == null) {
        return null;
      }

      final employeeId =
      _extractEmployeeId(user);

      if (employeeId == null ||
          employeeId <= 0) {
        return null;
      }

      return employeeId;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // EXTRACT EMPLOYEE ID
  // ============================================================

  int? _extractEmployeeId(dynamic user) {
    if (user is! Map) {
      return null;
    }

    // ----------------------------------------------------------
    // user['employee_id']
    // ----------------------------------------------------------

    final directEmployeeId =
    _parseInt(user['employee_id']);

    if (directEmployeeId != null &&
        directEmployeeId > 0) {
      return directEmployeeId;
    }

    // ----------------------------------------------------------
    // user['employee']['id']
    // ----------------------------------------------------------

    final employee =
    user['employee'];

    if (employee is Map) {
      final employeeId =
      _parseInt(employee['id']);

      if (employeeId != null &&
          employeeId > 0) {
        return employeeId;
      }
    }

    // ----------------------------------------------------------
    // user['data']['employee_id']
    // ----------------------------------------------------------

    final data =
    user['data'];

    if (data is Map) {
      final dataEmployeeId =
      _parseInt(data['employee_id']);

      if (dataEmployeeId != null &&
          dataEmployeeId > 0) {
        return dataEmployeeId;
      }

      // --------------------------------------------------------
      // user['data']['employee']['id']
      // --------------------------------------------------------

      final dataEmployee =
      data['employee'];

      if (dataEmployee is Map) {
        final employeeId =
        _parseInt(dataEmployee['id']);

        if (employeeId != null &&
            employeeId > 0) {
          return employeeId;
        }
      }
    }

    return null;
  }

  // ============================================================
  // PARSE INTEGER
  // ============================================================

  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // CHECK OUT
  // ============================================================

  Future<bool> submitCheckOut({
    required DateTime occurredAt,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String deviceId,
    required String uuid,
    File? photo,
    String? remarks,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // --------------------------------------------------------
      // GET LOGGED-IN EMPLOYEE ID
      // --------------------------------------------------------

      final employeeId =
      await _getEmployeeId();

      if (employeeId == null ||
          employeeId <= 0) {
        _errorMessage =
        'Employee ID haijapatikana. Tafadhali login tena.';

        return false;
      }

      // --------------------------------------------------------
      // USE PROVIDED DEVICE ID
      // --------------------------------------------------------

      String finalDeviceId = deviceId;

      if (finalDeviceId.trim().isEmpty) {
        finalDeviceId =
        await _deviceService.getDeviceName();
      }

      // --------------------------------------------------------
      // CHECK OUT
      // --------------------------------------------------------

      final attendance =
      await _attendanceRepository.checkOut(
        employeeId: employeeId,
        uuid: uuid,
        occurredAt:
        occurredAt
            .toUtc()
            .toIso8601String(),
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        deviceId: finalDeviceId,
        photo: photo,
        remarks: remarks,
      );

      // --------------------------------------------------------
      // STORE RESULT
      // --------------------------------------------------------

      _attendance = attendance;

      return true;
    } catch (e) {
      _errorMessage =
          e.toString().replaceFirst(
            'Exception: ',
            '',
          );

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }
}