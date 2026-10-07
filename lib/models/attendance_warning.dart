class AttendanceWarning {
  final bool hasWarning;
  final int threshold;
  final int consecutiveLateDays;
  final String requiredCheckIn;
  final WarningEmployee employee;
  final List<LateRecord> lateRecords;
  final String? message;
  final String? warningLetterUrl;

  AttendanceWarning({
    required this.hasWarning,
    required this.threshold,
    required this.consecutiveLateDays,
    required this.requiredCheckIn,
    required this.employee,
    required this.lateRecords,
    this.message,
    this.warningLetterUrl,
  });

  factory AttendanceWarning.fromJson(
      Map<String, dynamic> json,
      ) {
    return AttendanceWarning(
      hasWarning: json['has_warning'] == true,

      threshold: _toInt(
        json['threshold'],
      ),

      consecutiveLateDays: _toInt(
        json['consecutive_late_days'],
      ),

      requiredCheckIn:
      json['required_check_in']?.toString() ?? '08:00',

      employee: WarningEmployee.fromJson(
        Map<String, dynamic>.from(
          json['employee'] ?? {},
        ),
      ),

      lateRecords:
      (json['late_records'] as List? ?? [])
          .map(
            (item) => LateRecord.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList(),

      message: json['message']?.toString(),

      warningLetterUrl:
      json['warning_letter_url']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }
}


// ============================================================
// WARNING EMPLOYEE
// ============================================================

class WarningEmployee {
  final int? id;
  final String name;
  final String employeeNo;
  final String jobTitle;
  final String department;
  final String unit;

  WarningEmployee({
    this.id,
    required this.name,
    required this.employeeNo,
    required this.jobTitle,
    required this.department,
    required this.unit,
  });

  factory WarningEmployee.fromJson(
      Map<String, dynamic> json,
      ) {
    return WarningEmployee(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(
        json['id']?.toString() ?? '',
      ),

      name:
      json['name']?.toString() ??
          'Employee',

      employeeNo:
      json['employee_no']?.toString() ??
          '-',

      jobTitle:
      json['job_title']?.toString() ??
          'Employee',

      department:
      json['department']?.toString() ??
          '',

      unit:
      json['unit']?.toString() ??
          '',
    );
  }
}


// ============================================================
// LATE RECORD
// ============================================================

class LateRecord {
  final String date;
  final String checkIn;
  final int minutesLate;

  LateRecord({
    required this.date,
    required this.checkIn,
    required this.minutesLate,
  });

  factory LateRecord.fromJson(
      Map<String, dynamic> json,
      ) {
    return LateRecord(
      date:
      json['date']?.toString() ??
          '',

      checkIn:
      json['check_in']?.toString() ??
          '--:--',

      minutesLate:
      _toInt(
        json['minutes_late'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }
}