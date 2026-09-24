import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance.dart';
import '../repositories/attendance_repository.dart';
import '../services/device_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  AttendanceViewModel({
    AttendanceRepository? attendanceRepository,
    DeviceService? deviceService,
  })  : _attendanceRepository =
      attendanceRepository ?? AttendanceRepository(),
        _deviceService =
            deviceService ?? DeviceService.instance;

  final AttendanceRepository _attendanceRepository;
  final DeviceService _deviceService;



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

  bool get isLoadingMyAttendance =>
      _isLoadingMyAttendance;

  Future<void> loadMyAttendance({
    String? from,
    String? to,
  }) async {
    _isLoadingMyAttendance = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _myAttendances =
      await _attendanceRepository.getMyAttendance(
        from: from,
        to: to,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMyAttendance = false;
      notifyListeners();
    }
  }

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
      // Generate unique UUID for this attendance record
      final attendanceUuid = _uuid.v4();

      final deviceId =
      await _deviceService.getDeviceName();

      final occurredAt =
      DateTime.now().toUtc().toIso8601String();

      final attendance =
      await _attendanceRepository.checkIn(
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

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}