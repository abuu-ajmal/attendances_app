import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance.dart';
import '../repositories/attendance_repository.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  AttendanceViewModel({
    AttendanceRepository? attendanceRepository,
    DeviceService? deviceService,
    StorageService? storageService,
  })  : _attendanceRepository =
      attendanceRepository ?? AttendanceRepository(),
        _deviceService =
            deviceService ?? DeviceService.instance,
        _storageService =
            storageService ?? StorageService.instance;

  final AttendanceRepository _attendanceRepository;

  final DeviceService _deviceService;

  final StorageService _storageService;

  final Uuid _uuid = const Uuid();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Attendance? _attendance;

  Attendance? get attendance => _attendance;

  List<Attendance> _myAttendances = [];

  List<Attendance> get myAttendances => _myAttendances;

  bool _isLoadingMyAttendance = false;

  bool get isLoadingMyAttendance => _isLoadingMyAttendance;

  // ============================================================
  // GET CURRENT EMPLOYEE ID
  // ============================================================

  Future<int?> _getEmployeeId() async {
    try {
      final user = await _storageService.getUser();

      if (user == null) {
        return null;
      }

      final employeeId = _extractEmployeeId(user);

      if (employeeId == null || employeeId <= 0) {
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

    final directEmployeeId =
    _parseInt(user['employee_id']);

    if (directEmployeeId != null &&
        directEmployeeId > 0) {
      return directEmployeeId;
    }

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

    final data =
    user['data'];

    if (data is Map) {
      final dataEmployeeId =
      _parseInt(data['employee_id']);

      if (dataEmployeeId != null &&
          dataEmployeeId > 0) {
        return dataEmployeeId;
      }

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
  // CHECK IN
  // ============================================================

  Future<bool> checkIn({
    required double latitude,
    required double longitude,
    required double accuracy,
    File? photo,
    String? remarks,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // ----------------------------------------------------------
      // GET LOGGED-IN EMPLOYEE
      // ----------------------------------------------------------

      final employeeId =
      await _getEmployeeId();

      if (employeeId == null ||
          employeeId <= 0) {
        _errorMessage =
        'Employee ID haijapatikana. Tafadhali login tena.';

        return false;
      }

      // ----------------------------------------------------------
      // CREATE UUID
      // ----------------------------------------------------------

      final attendanceUuid =
      _uuid.v4();

      // ----------------------------------------------------------
      // GET DEVICE ID
      // ----------------------------------------------------------

      final deviceId =
      await _deviceService.getDeviceName();

      // ----------------------------------------------------------
      // UTC TIME
      // ----------------------------------------------------------

      final occurredAt =
      DateTime.now()
          .toUtc()
          .toIso8601String();

      // ----------------------------------------------------------
      // SAVE / SEND ATTENDANCE
      // ----------------------------------------------------------

      final attendance =
      await _attendanceRepository.checkIn(
        employeeId: employeeId,
        uuid: attendanceUuid,
        occurredAt: occurredAt,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        photo: photo,
        deviceId: deviceId,
        remarks: remarks,
      );

      _attendance = attendance;

      // ----------------------------------------------------------
      // REFRESH MY ATTENDANCE
      // ----------------------------------------------------------

      await loadMyAttendance();

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
  // LOAD MY ATTENDANCE
  // ============================================================

  Future<void> loadMyAttendance({
    String? from,
    String? to,
  }) async {
    _isLoadingMyAttendance = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // ----------------------------------------------------------
      // GET LOGGED-IN EMPLOYEE
      // ----------------------------------------------------------

      final employeeId =
      await _getEmployeeId();

      if (employeeId == null ||
          employeeId <= 0) {
        _errorMessage =
        'Employee ID haijapatikana. Tafadhali login tena.';

        return;
      }

      // ----------------------------------------------------------
      // GET ATTENDANCE
      // ----------------------------------------------------------

      _myAttendances =
      await _attendanceRepository.getMyAttendance(
        employeeId: employeeId,
        from: from,
        to: to,
      );
    } catch (e) {
      _errorMessage =
          e.toString().replaceFirst(
            'Exception: ',
            '',
          );
    } finally {
      _isLoadingMyAttendance = false;

      notifyListeners();
    }
  }

  // ============================================================
  // SYNC PENDING ATTENDANCE
  // ============================================================

  Future<int> syncPending() async {
    try {
      // ----------------------------------------------------------
      // GET LOGGED-IN EMPLOYEE
      // ----------------------------------------------------------

      final employeeId =
      await _getEmployeeId();

      if (employeeId == null ||
          employeeId <= 0) {
        return 0;
      }

      // ----------------------------------------------------------
      // SYNC
      // ----------------------------------------------------------

      final count =
      await _attendanceRepository
          .syncPendingAttendances(
        employeeId: employeeId,
      );

      // ----------------------------------------------------------
      // REFRESH AFTER SYNC
      // ----------------------------------------------------------

      if (count > 0) {
        await loadMyAttendance();
      }

      return count;
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // PENDING COUNT
  // ============================================================

  Future<int> pendingCount() async {
    try {
      final employeeId =
      await _getEmployeeId();

      if (employeeId == null ||
          employeeId <= 0) {
        return 0;
      }

      return await _attendanceRepository
          .getPendingCount(
        employeeId: employeeId,
      );
    } catch (_) {
      return 0;
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