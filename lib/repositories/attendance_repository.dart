import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/attendance.dart';
import '../services/attendance_file_service.dart';
import '../services/attendance_local_database.dart';
import '../services/storage_service.dart';

class AttendanceRepository {
AttendanceRepository({
StorageService? storageService,
AttendanceLocalDatabase? localDatabase,
AttendanceFileService? fileService,
})  : _storageService =
storageService ?? StorageService.instance,
_localDatabase =
localDatabase ?? AttendanceLocalDatabase.instance,
_fileService =
fileService ?? AttendanceFileService.instance;

final StorageService _storageService;
final AttendanceLocalDatabase _localDatabase;
final AttendanceFileService _fileService;

// ============================================================
// CHECK IN
// ============================================================

Future<Attendance> checkIn({
required int employeeId,
required String uuid,
required String occurredAt,
required double latitude,
required double longitude,
required double accuracy,
File? photo,
required String deviceId,
String? remarks,
}) async {
return _createAttendance(
employeeId: employeeId,
uuid: uuid,
type: 'check_in',
occurredAt: occurredAt,
latitude: latitude,
longitude: longitude,
accuracy: accuracy,
photo: photo,
deviceId: deviceId,
remarks: remarks,
);
}

// ============================================================
// CHECK OUT
// ============================================================

Future<Attendance> checkOut({
required int employeeId,
required String uuid,
required String occurredAt,
required double latitude,
required double longitude,
required double accuracy,
File? photo,
required String deviceId,
String? remarks,
}) async {
return _createAttendance(
employeeId: employeeId,
uuid: uuid,
type: 'check_out',
occurredAt: occurredAt,
latitude: latitude,
longitude: longitude,
accuracy: accuracy,
photo: photo,
deviceId: deviceId,
remarks: remarks,
);
}

// ============================================================
// CREATE ATTENDANCE
// ============================================================

Future<Attendance> _createAttendance({
required int employeeId,
required String uuid,
required String type,
required String occurredAt,
required double latitude,
required double longitude,
required double accuracy,
File? photo,
required String deviceId,
String? remarks,
}) async {
if (employeeId <= 0) {
throw Exception(
'Invalid employee ID.',
);
}

if (uuid.trim().isEmpty) {
throw Exception(
'Attendance UUID is required.',
);
}

if (type != 'check_in' && type != 'check_out') {
throw Exception(
'Invalid attendance type: $type',
);
}

// ============================================================
// SAVE PHOTO
// ============================================================

final permanentPhotoPath =
await _fileService.saveAttendancePhoto(
photo,
uuid,
);

// ============================================================
// LOCAL DATA
// ============================================================

final localData = <String, dynamic>{
'uuid': uuid,
'employee_id': employeeId,
'type': type,
'occurred_at': occurredAt,
'latitude': latitude,
'longitude': longitude,
'accuracy': accuracy,
'photo_path': permanentPhotoPath,
'device_id': deviceId,
'sync_status': 'pending',
'remarks': remarks?.trim(),
};

// ============================================================
// SAVE TO SQLITE FIRST
// ============================================================

await _localDatabase.insertAttendance(
localData,
);

// ============================================================
// TRY ONLINE SYNC
// ============================================================

try {
final synced = await _syncSingle(
localData,
);

return synced;
} catch (e) {
debugPrint(
'Attendance saved locally. Online sync failed: $e',
);

// ==========================================================
// INTERNET / SERVER NOT AVAILABLE
// RECORD REMAINS IN SQLITE AS PENDING
// ==========================================================

return Attendance.fromLocal(
localData,
);
}
}

// ============================================================
// SYNC ONE RECORD
// ============================================================

Future<Attendance> _syncSingle(
Map<String, dynamic> localData,
) async {
final token =
await _storageService.getToken();

if (token == null || token.isEmpty) {
throw Exception(
'Authentication token not available for synchronization.',
);
}

// ============================================================
// VALIDATE EMPLOYEE ID
// ============================================================

final employeeId =
_parseInt(localData['employee_id']);

if (employeeId == null || employeeId <= 0) {
throw Exception(
'Employee ID is missing from local attendance record.',
);
}

// ============================================================
// CREATE MULTIPART REQUEST
// ============================================================

final request = http.MultipartRequest(
'POST',
Uri.parse(ApiConfig.attendance),
);

request.headers.addAll({
'Accept': 'application/json',
'Authorization': 'Bearer $token',
});

// ============================================================
// REQUIRED FIELDS
// ============================================================

request.fields['uuid'] =
localData['uuid'].toString();

request.fields['type'] =
localData['type'].toString();

request.fields['occurred_at'] =
localData['occurred_at'].toString();

request.fields['latitude'] =
localData['latitude'].toString();

request.fields['longitude'] =
localData['longitude'].toString();

request.fields['accuracy'] =
localData['accuracy'].toString();

request.fields['device_id'] =
localData['device_id'].toString();

// ============================================================
// EMPLOYEE ID
// ============================================================
//
// NOTE:
// Normally Laravel identifies the employee from the
// authenticated user. We still keep employee_id in SQLite
// because your local database requires it.
//
// We do NOT send employee_id to the API unless your API
// explicitly requires it.
//
// ============================================================

// If your Laravel API requires employee_id, uncomment:
//
// request.fields['employee_id'] =
//     employeeId.toString();

// ============================================================
// REMARKS
// ============================================================

final remarks =
localData['remarks']?.toString();

if (remarks != null &&
remarks.trim().isNotEmpty) {
request.fields['remarks'] =
remarks.trim();
}

// ============================================================
// PHOTO
// ============================================================

final photoPath =
localData['photo_path']?.toString();

if (photoPath != null &&
photoPath.trim().isNotEmpty) {
final photoFile = File(photoPath);

if (await photoFile.exists()) {
request.files.add(
await http.MultipartFile.fromPath(
'photo',
photoFile.path,
),
);
}
}

// ============================================================
// SEND REQUEST
// ============================================================

final streamedResponse =
await request.send();

final response =
await http.Response.fromStream(
streamedResponse,
);

// ============================================================
// DEBUG
// ============================================================

debugPrint(
'========================================',
);

debugPrint(
'ATTENDANCE API RESPONSE',
);

debugPrint(
'URL: ${ApiConfig.attendance}',
);

debugPrint(
'STATUS CODE: ${response.statusCode}',
);

debugPrint(
'EMPLOYEE ID: $employeeId',
);

debugPrint(
'UUID: ${localData['uuid']}',
);

debugPrint(
'TYPE: ${localData['type']}',
);

debugPrint(
'BODY: ${response.body}',
);

debugPrint(
'========================================',
);

// ============================================================
// DECODE RESPONSE
// ============================================================

dynamic decoded;

try {
decoded = jsonDecode(
response.body,
);
} catch (_) {
decoded = {
'message': response.body,
};
}

// ============================================================
// SUCCESS
// ============================================================

if (response.statusCode >= 200 &&
response.statusCode < 300) {
Map<String, dynamic>? serverData;

if (decoded is Map<String, dynamic>) {
final data = decoded['data'];

if (data is Map<String, dynamic>) {
serverData = data;
} else {
// Some APIs may return the attendance
// directly without a "data" wrapper.
serverData = decoded;
}
}

// ==========================================================
// FALLBACK SERVER DATA
// ==========================================================

serverData ??= {
...localData,
'id': null,
'employee_id': employeeId,
'sync_status': 'synced',
};

// Make sure employee_id exists in returned data.
serverData['employee_id'] ??= employeeId;

// ==========================================================
// MARK SQLITE RECORD AS SYNCED
// ==========================================================

await _localDatabase.markAsSynced(
uuid: localData['uuid'].toString(),
serverId: _parseInt(
serverData['id'],
),
serverReceivedAt:
serverData['server_received_at']
    ?.toString(),
createdAt:
serverData['created_at']
    ?.toString(),
updatedAt:
serverData['updated_at']
    ?.toString(),
);

// ==========================================================
// RETURN SERVER ATTENDANCE
// ==========================================================

return Attendance.fromJson(
serverData,
);
}

// ============================================================
// SERVER ERROR
// ============================================================

String errorMessage =
'Failed to synchronize attendance.';

if (decoded is Map<String, dynamic>) {
errorMessage =
decoded['message']?.toString() ??
decoded['error']?.toString() ??
errorMessage;
}

throw Exception(
errorMessage,
);
}

// ============================================================
// SYNC ALL PENDING
// CURRENT EMPLOYEE ONLY
// ============================================================

Future<int> syncPendingAttendances({
required int employeeId,
}) async {
if (employeeId <= 0) {
throw Exception(
'Invalid employee ID.',
);
}

final pending =
await _localDatabase.getPendingAttendances(
employeeId: employeeId,
);

debugPrint(
'========================================',
);

debugPrint(
'ATTENDANCE SYNC START',
);

debugPrint(
'EMPLOYEE ID: $employeeId',
);

debugPrint(
'PENDING RECORDS: ${pending.length}',
);

debugPrint(
'========================================',
);

if (pending.isEmpty) {
debugPrint(
'No pending attendance records.',
);

return 0;
}

int syncedCount = 0;

for (final record in pending) {
try {
debugPrint(
'----------------------------------------',
);

debugPrint(
'SYNCING ATTENDANCE',
);

debugPrint(
'EMPLOYEE ID: ${record['employee_id']}',
);

debugPrint(
'UUID: ${record['uuid']}',
);

debugPrint(
'TYPE: ${record['type']}',
);

debugPrint(
'OCCURRED AT: ${record['occurred_at']}',
);

debugPrint(
'LATITUDE: ${record['latitude']}',
);

debugPrint(
'LONGITUDE: ${record['longitude']}',
);

debugPrint(
'PHOTO: ${record['photo_path']}',
);

debugPrint(
'DEVICE: ${record['device_id']}',
);

debugPrint(
'STATUS: ${record['sync_status']}',
);

await _syncSingle(
record,
);

syncedCount++;

debugPrint(
'SYNC SUCCESS',
);
} catch (e, stackTrace) {
debugPrint(
'SYNC FAILED',
);

debugPrint(
'UUID: ${record['uuid']}',
);

debugPrint(
'ERROR: $e',
);

debugPrint(
stackTrace.toString(),
);

// Keep as pending so that the next sync
// attempt can retry it.
await _localDatabase.markAsFailed(
record['uuid'].toString(),
);
}
}

debugPrint(
'========================================',
);

debugPrint(
'ATTENDANCE SYNC FINISHED',
);

debugPrint(
'EMPLOYEE ID: $employeeId',
);

debugPrint(
'SYNCED: $syncedCount',
);

debugPrint(
'TOTAL PENDING: ${pending.length}',
);

debugPrint(
'========================================',
);

return syncedCount;
}

// ============================================================
// PENDING COUNT
// CURRENT EMPLOYEE ONLY
// ============================================================

Future<int> getPendingCount({
required int employeeId,
}) async {
return _localDatabase.pendingCount(
employeeId: employeeId,
);
}

// ============================================================
// LOCAL ATTENDANCES
// CURRENT EMPLOYEE ONLY
// ============================================================

Future<List<Attendance>> getLocalAttendances({
required int employeeId,
String? from,
String? to,
}) async {
final records =
await _localDatabase.getAllAttendances(
employeeId: employeeId,
from: from,
to: to,
);

return records
    .map(
(record) => Attendance.fromLocal(
record,
),
)
    .toList();
}

// ============================================================
// CHECK WHETHER EMPLOYEE HAS CHECKED IN TODAY
// ============================================================

Future<bool> hasCheckedInToday({
required int employeeId,
required String date,
}) async {
return _localDatabase.hasCheckedInToday(
employeeId: employeeId,
date: date,
);
}

// ============================================================
// CHECK WHETHER EMPLOYEE HAS CHECKED OUT TODAY
// ============================================================

Future<bool> hasCheckedOutToday({
required int employeeId,
required String date,
}) async {
return _localDatabase.hasCheckedOutToday(
employeeId: employeeId,
date: date,
);
}

// ============================================================
// MY ATTENDANCES
// ONLINE + LOCAL PENDING
// CURRENT EMPLOYEE ONLY
// ============================================================

Future<List<Attendance>> getMyAttendance({
required int employeeId,
String? from,
String? to,
int perPage = 30,
}) async {
if (employeeId <= 0) {
throw Exception(
'Invalid employee ID.',
);
}

final token =
await _storageService.getToken();

// ============================================================
// NO TOKEN
// OFFLINE MODE
// ============================================================

if (token == null || token.isEmpty) {
return getLocalAttendances(
employeeId: employeeId,
from: from,
to: to,
);
}

// ============================================================
// QUERY PARAMETERS
// ============================================================

final queryParameters =
<String, String>{
'per_page': perPage.toString(),
};

if (from != null &&
from.trim().isNotEmpty) {
queryParameters['from'] =
from.trim();
}

if (to != null &&
to.trim().isNotEmpty) {
queryParameters['to'] =
to.trim();
}

// ============================================================
// REQUEST
// ============================================================

try {
final uri = Uri.parse(
ApiConfig.myAttendance,
).replace(
queryParameters:
queryParameters,
);

final response = await http.get(
uri,
headers: {
'Accept': 'application/json',
'Authorization':
'Bearer $token',
},
);

debugPrint(
'========================================',
);

debugPrint(
'MY ATTENDANCE API',
);

debugPrint(
'URL: $uri',
);

debugPrint(
'STATUS: ${response.statusCode}',
);

debugPrint(
'BODY: ${response.body}',
);

debugPrint(
'========================================',
);

// ==========================================================
// DECODE
// ==========================================================

dynamic decoded;

try {
decoded = jsonDecode(
response.body,
);
} catch (_) {
decoded = {
'message': response.body,
};
}

// ==========================================================
// SERVER SUCCESS
// ==========================================================

if (response.statusCode >= 200 &&
response.statusCode < 300) {
final List<Attendance>
serverRecords = [];

if (decoded
is Map<String, dynamic>) {
final data =
decoded['data'];

// Laravel pagination:
//
// data:
// {
//   current_page: 1,
//   data: [...]
// }
//

if (data
is Map<String, dynamic>) {
final records =
data['data'];

if (records is List) {
for (final item
in records) {
if (item
is Map<String, dynamic>) {
try {
serverRecords.add(
Attendance.fromJson(
item,
),
);
} catch (e) {
debugPrint(
'Failed to parse attendance: $e',
);
}
}
}
}
}

// Some APIs may return:
//
// data: [...]
//

else if (data is List) {
for (final item
in data) {
if (item
is Map<String, dynamic>) {
try {
serverRecords.add(
Attendance.fromJson(
item,
),
);
} catch (e) {
debugPrint(
'Failed to parse attendance: $e',
);
}
}
}
}
}

// ========================================================
// ADD LOCAL PENDING RECORDS
// ========================================================

final localRecords =
await getLocalAttendances(
employeeId: employeeId,
from: from,
to: to,
);

final pending =
localRecords.where(
(item) =>
item.syncStatus ==
'pending',
);

// ========================================================
// PREVENT DUPLICATES USING UUID
// ========================================================

final existingUuids =
serverRecords
    .map(
(item) => item.uuid,
)
    .whereType<String>()
    .toSet();

// ========================================================
// ADD ONLY PENDING LOCAL RECORDS
// THAT DO NOT ALREADY EXIST ON SERVER
// ========================================================

for (final item
in pending) {
final uuid = item.uuid;

if (uuid == null ||
uuid.trim().isEmpty) {
continue;
}

if (!existingUuids
    .contains(uuid)) {
serverRecords.add(
item,
);
}
}

// ========================================================
// SORT BY OCCURRED AT DESC
// ========================================================

serverRecords.sort(
(a, b) {
final aDate =
_parseDate(a.occurredAt);

final bDate =
_parseDate(b.occurredAt);

return bDate.compareTo(
aDate,
);
},
);

return serverRecords;
}

// ==========================================================
// SERVER ERROR
// FALLBACK TO LOCAL
// ==========================================================

return getLocalAttendances(
employeeId: employeeId,
from: from,
to: to,
);
} catch (e) {
// ==========================================================
// INTERNET NOT AVAILABLE
// FALLBACK TO SQLITE
// ==========================================================

debugPrint(
'MY ATTENDANCE OFFLINE FALLBACK: $e',
);

return getLocalAttendances(
employeeId: employeeId,
from: from,
to: to,
);
}
}

// ============================================================
// DELETE OLD SYNCED RECORDS
// ============================================================

Future<void> deleteSyncedOlderThan({
required int employeeId,
required DateTime date,
}) async {
await _localDatabase
    .deleteSyncedOlderThan(
employeeId: employeeId,
date: date,
);
}

// ============================================================
// EMPLOYEE LOCAL ATTENDANCE COUNT
// ============================================================

Future<int> attendanceCount({
required int employeeId,
}) async {
return _localDatabase.attendanceCount(
employeeId: employeeId,
);
}

// ============================================================
// CLEAR EMPLOYEE LOCAL DATA
// ============================================================

Future<void> clearEmployeeAttendance({
required int employeeId,
}) async {
await _localDatabase
    .clearEmployeeAttendance(
employeeId,
);
}

// ============================================================
// DEBUG LOCAL DATABASE
// ============================================================

Future<List<Map<String, dynamic>>>
debugAllLocalRecords() async {
return _localDatabase
    .debugAllRecords();
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

if (value is double) {
return value.toInt();
}

return int.tryParse(
value.toString(),
);
}

// ============================================================
// PARSE DATE
// ============================================================

DateTime _parseDate(String? value) {
if (value == null ||
value.trim().isEmpty) {
return DateTime.fromMillisecondsSinceEpoch(
0,
);
}

try {
return DateTime.parse(
value,
);
} catch (_) {
return DateTime.fromMillisecondsSinceEpoch(
0,
);
}
}
}

