
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../repositories/attendance_repository.dart';
import '../services/storage_service.dart';

class AttendanceSyncService {
AttendanceSyncService._();

static final AttendanceSyncService instance =
AttendanceSyncService._();

// ============================================================
// SERVICES
// ============================================================

final AttendanceRepository _attendanceRepository =
AttendanceRepository();

final StorageService _storageService =
StorageService.instance;

// ============================================================
// CONNECTIVITY
// ============================================================

StreamSubscription<List<ConnectivityResult>>?
_subscription;

// ============================================================
// SYNC LOCK
// ============================================================

bool _syncing = false;

// ============================================================
// START
// ============================================================

Future<void> start() async {
// Try sync immediately.
await syncNow();

// Avoid creating multiple listeners.
if (_subscription != null) {
return;
}

_subscription =
Connectivity()
    .onConnectivityChanged
    .listen(
(results) async {
final connected =
results.any(
(result) =>
result !=
ConnectivityResult.none,
);

if (!connected) {
return;
}

await syncNow();
},
);
}

// ============================================================
// SYNC NOW
// ============================================================

Future<int> syncNow() async {
// Prevent duplicate sync operations.
if (_syncing) {
return 0;
}

_syncing = true;

try {
// ========================================================
// GET LOGGED-IN USER
// ========================================================

final user =
await _storageService.getUser();

if (user == null) {
return 0;
}

// ========================================================
// GET EMPLOYEE ID
// ========================================================

final employeeId =
_extractEmployeeId(user);

if (employeeId == null ||
employeeId <= 0) {
return 0;
}

// ========================================================
// SYNC CURRENT EMPLOYEE ONLY
// ========================================================

return await _attendanceRepository
    .syncPendingAttendances(
employeeId: employeeId,
);
} catch (e) {
// Never crash the application because of sync.
return 0;
} finally {
_syncing = false;
}
}

// ============================================================
// EXTRACT EMPLOYEE ID
// ============================================================

int? _extractEmployeeId(
dynamic user,
) {
if (user == null) {
return null;
}

// ==========================================================
// USER AS MAP
// ==========================================================

if (user is Map) {
// --------------------------------------------------------
// Direct:
//
// {
//   "employee_id": 25
// }
// --------------------------------------------------------

final employeeId =
_parseInt(
user['employee_id'],
);

if (employeeId != null &&
employeeId > 0) {
return employeeId;
}

// --------------------------------------------------------
// Nested:
//
// {
//   "employee": {
//     "id": 25
//   }
// }
// --------------------------------------------------------

final employee =
user['employee'];

if (employee is Map) {
final nestedEmployeeId =
_parseInt(
employee['id'],
);

if (nestedEmployeeId != null &&
nestedEmployeeId > 0) {
return nestedEmployeeId;
}
}

// --------------------------------------------------------
// Nested data:
//
// {
//   "data": {
//     "employee_id": 25
//   }
// }
// --------------------------------------------------------

final data =
user['data'];

if (data is Map) {
final dataEmployeeId =
_parseInt(
data['employee_id'],
);

if (dataEmployeeId != null &&
dataEmployeeId > 0) {
return dataEmployeeId;
}

final dataEmployee =
data['employee'];

if (dataEmployee is Map) {
final nestedId =
_parseInt(
dataEmployee['id'],
);

if (nestedId != null &&
nestedId > 0) {
return nestedId;
}
}
}
}

return null;
}

// ============================================================
// PARSE INTEGER
// ============================================================

int? _parseInt(
dynamic value,
) {
if (value == null) {
return null;
}

if (value is int) {
return value;
}

if (value is double) {
return value.toInt();
}

return int.tryParse(
value.toString(),
);
}

// ============================================================
// DISPOSE
// ============================================================

Future<void> dispose() async {
await _subscription?.cancel();

_subscription = null;
}
}

