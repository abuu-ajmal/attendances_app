
class Attendance {
final int? id;
final String? uuid;
final int? employeeId;
final String? type;
final String? occurredAt;
final String? serverReceivedAt;

final double? latitude;
final double? longitude;
final double? accuracy;

final String? photoPath;
final String? deviceId;
final String? syncStatus;
final String? remarks;

final String? createdAt;
final String? updatedAt;

Attendance({
this.id,
this.uuid,
this.employeeId,
this.type,
this.occurredAt,
this.serverReceivedAt,
this.latitude,
this.longitude,
this.accuracy,
this.photoPath,
this.deviceId,
this.syncStatus,
this.remarks,
this.createdAt,
this.updatedAt,
});

factory Attendance.fromJson(
Map<String, dynamic> json,
) {
return Attendance(
id: json['id'] as int?,

uuid: json['uuid']?.toString(),

employeeId: json['employee_id'] is int
? json['employee_id'] as int
    : int.tryParse(
json['employee_id']?.toString() ?? '',
),

type: json['type']?.toString(),

occurredAt:
json['occurred_at']?.toString(),

serverReceivedAt:
json['server_received_at']?.toString(),

latitude: json['latitude'] != null
? double.tryParse(
json['latitude'].toString(),
)
    : null,

longitude: json['longitude'] != null
? double.tryParse(
json['longitude'].toString(),
)
    : null,

accuracy: json['accuracy'] != null
? double.tryParse(
json['accuracy'].toString(),
)
    : null,

photoPath:
json['photo_path']?.toString(),

deviceId:
json['device_id']?.toString(),

syncStatus:
json['sync_status']?.toString(),

remarks:
json['remarks']?.toString(),

createdAt:
json['created_at']?.toString(),

updatedAt:
json['updated_at']?.toString(),
);
}
}

