
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/attendance.dart';
import '../services/storage_service.dart';

class AttendanceRepository {
AttendanceRepository({
StorageService? storageService,
}) : _storageService =
storageService ?? StorageService.instance;

final StorageService _storageService;

// ============================================================
// CHECK IN
// ============================================================

Future<Attendance> checkIn({
required String uuid,
required String occurredAt,
required double latitude,
required double longitude,
required double accuracy,
File? photo,
required String deviceId,
String? remarks,
}) async {
final token = await _storageService.getToken();

if (token == null || token.isEmpty) {
throw Exception('Authentication token not found.');
}

final request = http.MultipartRequest(
'POST',
Uri.parse(ApiConfig.attendance),
);

request.headers.addAll({
'Accept': 'application/json',
'Authorization': 'Bearer $token',
});

request.fields['uuid'] = uuid;
request.fields['type'] = 'check_in';
request.fields['occurred_at'] = occurredAt;
request.fields['latitude'] = latitude.toString();
request.fields['longitude'] = longitude.toString();
request.fields['accuracy'] = accuracy.toString();
request.fields['device_id'] = deviceId;

if (remarks != null && remarks.trim().isNotEmpty) {
request.fields['remarks'] = remarks.trim();
}

if (photo != null) {
request.files.add(
await http.MultipartFile.fromPath(
'photo',
photo.path,
),
);
}

final streamedResponse = await request.send();

final response =
await http.Response.fromStream(streamedResponse);

dynamic decoded;

try {
decoded = jsonDecode(response.body);
} catch (_) {
decoded = {
'message': response.body,
};
}

if (response.statusCode >= 200 &&
response.statusCode < 300) {
if (decoded is Map<String, dynamic>) {
final data = decoded['data'];

if (data is Map<String, dynamic>) {
return Attendance.fromJson(data);
}
}

throw Exception(
'Attendance was recorded but response data was not returned.',
);
}

if (decoded is Map<String, dynamic>) {
throw Exception(
decoded['message']?.toString() ??
'Failed to record attendance.',
);
}

throw Exception(
'Failed to record attendance.',
);
}

// ============================================================
// CHECK OUT
// ============================================================

Future<Attendance> checkOut({
required String uuid,
required String occurredAt,
required double latitude,
required double longitude,
required double accuracy,
File? photo,
required String deviceId,
String? remarks,
}) async {
final token = await _storageService.getToken();

if (token == null || token.isEmpty) {
throw Exception('Authentication token not found.');
}

final request = http.MultipartRequest(
'POST',
Uri.parse(ApiConfig.attendance),
);

request.headers.addAll({
'Accept': 'application/json',
'Authorization': 'Bearer $token',
});

request.fields['uuid'] = uuid;
request.fields['type'] = 'check_out';
request.fields['occurred_at'] = occurredAt;
request.fields['latitude'] = latitude.toString();
request.fields['longitude'] = longitude.toString();
request.fields['accuracy'] = accuracy.toString();
request.fields['device_id'] = deviceId;

if (remarks != null && remarks.trim().isNotEmpty) {
request.fields['remarks'] = remarks.trim();
}

if (photo != null) {
request.files.add(
await http.MultipartFile.fromPath(
'photo',
photo.path,
),
);
}

final streamedResponse = await request.send();

final response =
await http.Response.fromStream(streamedResponse);

dynamic decoded;

try {
decoded = jsonDecode(response.body);
} catch (_) {
decoded = {
'message': response.body,
};
}

if (response.statusCode >= 200 &&
response.statusCode < 300) {
if (decoded is Map<String, dynamic>) {
final data = decoded['data'];

if (data is Map<String, dynamic>) {
return Attendance.fromJson(data);
}
}

throw Exception(
'Attendance was recorded but response data was not returned.',
);
}

if (decoded is Map<String, dynamic>) {
throw Exception(
decoded['message']?.toString() ??
'Failed to record attendance.',
);
}

throw Exception(
'Failed to record attendance.',
);
}

// ============================================================
// MY ATTENDANCES
// ============================================================

Future<List<Attendance>> getMyAttendance({
String? from,
String? to,
int perPage = 30,
}) async {
final token = await _storageService.getToken();

if (token == null || token.isEmpty) {
throw Exception('Authentication token not found.');
}

final queryParameters = <String, String>{
'per_page': perPage.toString(),
};

if (from != null && from.trim().isNotEmpty) {
queryParameters['from'] = from;
}

if (to != null && to.trim().isNotEmpty) {
queryParameters['to'] = to;
}

final uri = Uri.parse(
ApiConfig.myAttendance,
).replace(
queryParameters: queryParameters,
);

final response = await http.get(
uri,
headers: {
'Accept': 'application/json',
'Authorization': 'Bearer $token',
},
);

dynamic decoded;

try {
decoded = jsonDecode(response.body);
} catch (_) {
decoded = {
'message': response.body,
};
}

if (response.statusCode >= 200 &&
response.statusCode < 300) {
if (decoded is Map<String, dynamic>) {
final data = decoded['data'];

if (data is Map<String, dynamic>) {
final records = data['data'];

if (records is List) {
return records
    .whereType<Map<String, dynamic>>()
    .map(Attendance.fromJson)
    .toList();
}
}
}

return [];
}

if (decoded is Map<String, dynamic>) {
throw Exception(
decoded['message']?.toString() ??
'Failed to load attendance.',
);
}

throw Exception(
'Failed to load attendance.',
);
}
}

