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
      id: toInt(json['id']),

      uuid: json['uuid']?.toString(),

      employeeId: toInt(
        json['employee_id'],
      ),

      type: json['type']?.toString(),

      occurredAt:
      json['occurred_at']?.toString(),

      serverReceivedAt:
      json['server_received_at']?.toString(),

      latitude:
      _toDouble(json['latitude']),

      longitude:
      _toDouble(json['longitude']),

      accuracy:
      _toDouble(json['accuracy']),

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

  factory Attendance.fromLocal(
      Map<String, dynamic> data,
      ) {
    return Attendance(
      id: toInt(data['server_id'] ?? data['id']),
      uuid: data['uuid']?.toString(),
      employeeId: toInt(data['employee_id']),
      type: data['type']?.toString(),
      occurredAt: data['occurred_at']?.toString(),
      serverReceivedAt:
      data['server_received_at']?.toString(),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      accuracy: _toDouble(data['accuracy']),
      photoPath: data['photo_path']?.toString(),
      deviceId: data['device_id']?.toString(),
      syncStatus: data['sync_status']?.toString(),
      remarks: data['remarks']?.toString(),
      createdAt: data['created_at']?.toString(),
      updatedAt: data['updated_at']?.toString(),
    );
  }

  static int? toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }
}