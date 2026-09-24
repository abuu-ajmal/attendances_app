class DashboardModel {
  final String date;
  final int totalEmployees;
  final int checkedIn;
  final int checkedOut;
  final int notCheckedIn;

  DashboardModel({
    required this.date,
    required this.totalEmployees,
    required this.checkedIn,
    required this.checkedOut,
    required this.notCheckedIn,
  });

  factory DashboardModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return DashboardModel(
      date: json['date']?.toString() ?? '',
      totalEmployees:
      int.tryParse(
        json['total_employees'].toString(),
      ) ??
          0,
      checkedIn:
      int.tryParse(
        json['checked_in'].toString(),
      ) ??
          0,
      checkedOut:
      int.tryParse(
        json['checked_out'].toString(),
      ) ??
          0,
      notCheckedIn:
      int.tryParse(
        json['not_checked_in'].toString(),
      ) ??
          0,
    );
  }
}