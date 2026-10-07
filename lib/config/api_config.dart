class ApiConfig {
  ApiConfig._();

  static const String baseUrl =
      'http://10.10.89.150:8000/api';

  static const String login =
      '$baseUrl/auth/login';

  static const String me =
      '$baseUrl/auth/me';

  static const String logout =
      '$baseUrl/auth/logout';

  static const String devices =
      '$baseUrl/devices';

  static const String dashboard =
      '$baseUrl/dashboard';

  static const String attendance =
      '$baseUrl/attendance';

  static const String myAttendance =
      '$baseUrl/attendance/my';

  static String get myAttendanceWarning =>
      '$baseUrl/attendance/my/warning';

  static String get myAttendanceWarningLetter =>
      '$baseUrl/attendance/my/warning-letter';
}