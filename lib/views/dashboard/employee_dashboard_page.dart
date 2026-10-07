import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attendance.dart';
import '../../repositories/attendance_repository.dart';
import '../../services/storage_service.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/dashboard_view_model.dart';

import '../attendances/attendance_history_page.dart';
import '../attendances/attendance_page.dart';
import '../attendances/check_out_page.dart';
import '../attendances/my_attendance_page.dart';
import '../attendances/notification_page.dart';
import '../auth/login_page.dart';

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({
    super.key,
  });

  @override
  State<EmployeeDashboardPage> createState() =>
      _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState
    extends State<EmployeeDashboardPage> {
  // ==========================================================
  // SERVICES
  // ==========================================================

  final AttendanceRepository _attendanceRepository =
  AttendanceRepository();

  final StorageService _storageService =
      StorageService.instance;

  // ==========================================================
  // TODAY ATTENDANCE
  // ==========================================================

  bool hasCheckedInToday = false;
  bool hasCheckedOutToday = false;

  bool _isCheckingTodayAttendance = false;

  // ==========================================================
  // MONTHLY SUMMARY
  // ==========================================================

  int monthlyPresent = 0;
  int monthlyLate = 0;
  int monthlyAbsent = 0;

  bool _isLoadingMonthlySummary = false;

  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<DashboardViewModel>().loadDashboard();

      _checkTodayAttendance();
      _loadMonthlyAttendance();
    });
  }

  // ==========================================================
  // GET EMPLOYEE ID
  // ==========================================================

  Future<int?> _getEmployeeId() async {
    try {
      final user = await _storageService.getUser();

      return _extractEmployeeId(user);
    } catch (e) {
      debugPrint(
        'GET EMPLOYEE ID ERROR: $e',
      );

      return null;
    }
  }

  // ==========================================================
  // EXTRACT EMPLOYEE ID
  // ==========================================================

  int? _extractEmployeeId(dynamic user) {
    if (user == null) {
      return null;
    }

    if (user is! Map) {
      return null;
    }

    // --------------------------------------------------------
    // DIRECT:
    // employee_id
    // --------------------------------------------------------

    final directEmployeeId =
    _parseInt(user['employee_id']);

    if (directEmployeeId != null &&
        directEmployeeId > 0) {
      return directEmployeeId;
    }

    // --------------------------------------------------------
    // USER:
    // employee: { id: ... }
    // --------------------------------------------------------

    final employee = user['employee'];

    if (employee is Map) {
      final employeeId =
      _parseInt(employee['id']);

      if (employeeId != null &&
          employeeId > 0) {
        return employeeId;
      }
    }

    // --------------------------------------------------------
    // DATA:
    // data: { employee_id: ... }
    // --------------------------------------------------------

    final data = user['data'];

    if (data is Map) {
      final dataEmployeeId =
      _parseInt(data['employee_id']);

      if (dataEmployeeId != null &&
          dataEmployeeId > 0) {
        return dataEmployeeId;
      }

      // ------------------------------------------------------
      // DATA EMPLOYEE:
      // data: {
      //   employee: {
      //     id: ...
      //   }
      // }
      // ------------------------------------------------------

      final dataEmployee =
      data['employee'];

      if (dataEmployee is Map) {
        final dataEmployeeId =
        _parseInt(dataEmployee['id']);

        if (dataEmployeeId != null &&
            dataEmployeeId > 0) {
          return dataEmployeeId;
        }
      }
    }

    return null;
  }

  // ==========================================================
  // PARSE INT
  // ==========================================================

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

  // ==========================================================
  // CHECK TODAY ATTENDANCE
  // ==========================================================

  Future<void> _checkTodayAttendance() async {
    if (_isCheckingTodayAttendance) {
      return;
    }

    _isCheckingTodayAttendance = true;

    try {
      // ------------------------------------------------------
      // GET EMPLOYEE ID
      // ------------------------------------------------------

      final employeeId = await _getEmployeeId();

      if (employeeId == null ||
          employeeId <= 0) {
        debugPrint(
          'CHECK TODAY: Employee ID haijapatikana.',
        );

        return;
      }

      // ------------------------------------------------------
      // TODAY DATE
      // ------------------------------------------------------

      final now = DateTime.now();

      final today = _formatDate(now);

      debugPrint(
        'CHECK TODAY ATTENDANCE',
      );

      debugPrint(
        'EMPLOYEE ID: $employeeId',
      );

      debugPrint(
        'DATE: $today',
      );

      // ------------------------------------------------------
      // GET ATTENDANCE
      // ------------------------------------------------------

      final List<Attendance> attendances =
      await _attendanceRepository.getMyAttendance(
        employeeId: employeeId,
        from: today,
        to: today,
        perPage: 100,
      );

      debugPrint(
        'TODAY ATTENDANCE COUNT: '
            '${attendances.length}',
      );

      bool checkedIn = false;
      bool checkedOut = false;

      // ------------------------------------------------------
      // CHECK RECORDS
      // ------------------------------------------------------

      for (final attendance in attendances) {
        final occurredAtString =
            attendance.occurredAt;

        if (occurredAtString == null ||
            occurredAtString.trim().isEmpty) {
          continue;
        }

        final occurredAt =
        DateTime.tryParse(
          occurredAtString,
        );

        if (occurredAt == null) {
          continue;
        }

        final localDate =
        occurredAt.toLocal();

        final isToday =
            localDate.year == now.year &&
                localDate.month == now.month &&
                localDate.day == now.day;

        if (!isToday) {
          continue;
        }

        // ----------------------------------------------------
        // CHECK IN
        // ----------------------------------------------------

        if (attendance.type == 'check_in') {
          checkedIn = true;

          debugPrint(
            'TODAY CHECK IN FOUND: '
                '$occurredAtString',
          );
        }

        // ----------------------------------------------------
        // CHECK OUT
        // ----------------------------------------------------

        if (attendance.type == 'check_out') {
          checkedOut = true;

          debugPrint(
            'TODAY CHECK OUT FOUND: '
                '$occurredAtString',
          );
        }
      }

      // ------------------------------------------------------
      // UPDATE UI
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }

      setState(() {
        hasCheckedInToday = checkedIn;
        hasCheckedOutToday = checkedOut;
      });

      debugPrint(
        'TODAY ATTENDANCE => '
            'checkIn=$checkedIn, '
            'checkOut=$checkedOut',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'FAILED TO CHECK TODAY ATTENDANCE: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      _isCheckingTodayAttendance = false;
    }
  }

  // ==========================================================
  // LOAD MONTHLY ATTENDANCE
  // ==========================================================

  Future<void> _loadMonthlyAttendance() async {
    if (_isLoadingMonthlySummary) {
      return;
    }

    _isLoadingMonthlySummary = true;

    try {
      // ------------------------------------------------------
      // GET EMPLOYEE ID
      // ------------------------------------------------------

      final employeeId = await _getEmployeeId();

      if (employeeId == null ||
          employeeId <= 0) {
        debugPrint(
          'MONTHLY ATTENDANCE: Employee ID haijapatikana.',
        );

        return;
      }

      final now = DateTime.now();

      // ------------------------------------------------------
      // FIRST DAY OF MONTH
      // ------------------------------------------------------

      final firstDayOfMonth = DateTime(
        now.year,
        now.month,
        1,
      );

      // ------------------------------------------------------
      // LAST DAY OF MONTH
      // ------------------------------------------------------

      final lastDayOfMonth = DateTime(
        now.year,
        now.month + 1,
        0,
      );

      final from =
      _formatDate(firstDayOfMonth);

      final to =
      _formatDate(lastDayOfMonth);

      debugPrint(
        '======================================',
      );

      debugPrint(
        'MONTHLY ATTENDANCE',
      );

      debugPrint(
        'EMPLOYEE ID: $employeeId',
      );

      debugPrint(
        'FROM: $from',
      );

      debugPrint(
        'TO: $to',
      );

      debugPrint(
        '======================================',
      );

      // ------------------------------------------------------
      // GET ATTENDANCE
      // ------------------------------------------------------

      final List<Attendance> attendances =
      await _attendanceRepository.getMyAttendance(
        employeeId: employeeId,
        from: from,
        to: to,
        perPage: 100,
      );

      debugPrint(
        'TOTAL ATTENDANCE RECEIVED: '
            '${attendances.length}',
      );

      // ------------------------------------------------------
      // FIRST CHECK-IN OF EACH DAY
      // ------------------------------------------------------

      final Map<String, DateTime>
      checkInsByDay = {};

      for (final attendance in attendances) {
        if (attendance.type != 'check_in') {
          continue;
        }

        final occurredAtString =
            attendance.occurredAt;

        if (occurredAtString == null ||
            occurredAtString.trim().isEmpty) {
          continue;
        }

        final occurredAt =
        DateTime.tryParse(
          occurredAtString,
        );

        if (occurredAt == null) {
          debugPrint(
            'Could not parse occurredAt: '
                '$occurredAtString',
          );

          continue;
        }

        final localDate =
        occurredAt.toLocal();

        final dayKey =
            '${localDate.year}-'
            '${localDate.month.toString().padLeft(2, '0')}-'
            '${localDate.day.toString().padLeft(2, '0')}';

        // ----------------------------------------------------
        // KEEP FIRST CHECK-IN
        // ----------------------------------------------------

        if (!checkInsByDay.containsKey(dayKey) ||
            localDate.isBefore(
              checkInsByDay[dayKey]!,
            )) {
          checkInsByDay[dayKey] = localDate;
        }
      }

      // ------------------------------------------------------
      // CALCULATE PRESENT / LATE
      // ------------------------------------------------------

      int present = 0;
      int late = 0;

      const int workStartHour = 8;
      const int workStartMinute = 0;

      checkInsByDay.forEach(
            (day, checkInTime) {
          final workStart = DateTime(
            checkInTime.year,
            checkInTime.month,
            checkInTime.day,
            workStartHour,
            workStartMinute,
          );

          if (checkInTime.isAfter(
            workStart,
          )) {
            late++;

            debugPrint(
              'LATE => '
                  '$day $checkInTime',
            );
          } else {
            present++;

            debugPrint(
              'PRESENT => '
                  '$day $checkInTime',
            );
          }
        },
      );

      // ------------------------------------------------------
      // CALCULATE ABSENT
      // ------------------------------------------------------

      int absent = 0;

      DateTime currentDay =
          firstDayOfMonth;

      while (!currentDay.isAfter(
        lastDayOfMonth,
      )) {
        final isWeekend =
            currentDay.weekday ==
                DateTime.saturday ||
                currentDay.weekday ==
                    DateTime.sunday;

        if (!isWeekend) {
          final dayKey =
              '${currentDay.year}-'
              '${currentDay.month.toString().padLeft(2, '0')}-'
              '${currentDay.day.toString().padLeft(2, '0')}';

          final isToday =
              currentDay.year == now.year &&
                  currentDay.month == now.month &&
                  currentDay.day == now.day;

          if (!isToday &&
              !checkInsByDay.containsKey(
                dayKey,
              )) {
            absent++;
          }
        }

        currentDay = currentDay.add(
          const Duration(days: 1),
        );
      }

      // ------------------------------------------------------
      // DEBUG SUMMARY
      // ------------------------------------------------------

      debugPrint(
        '======================================',
      );

      debugPrint(
        'FINAL MONTHLY SUMMARY',
      );

      debugPrint(
        'PRESENT: $present',
      );

      debugPrint(
        'LATE: $late',
      );

      debugPrint(
        'ABSENT: $absent',
      );

      debugPrint(
        '======================================',
      );

      // ------------------------------------------------------
      // UPDATE UI
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }

      setState(() {
        monthlyPresent = present;
        monthlyLate = late;
        monthlyAbsent = absent;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'MONTHLY ATTENDANCE ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      _isLoadingMonthlySummary = false;
    }
  }

  // ==========================================================
  // REFRESH DASHBOARD
  // ==========================================================

  Future<void> _refreshDashboard() async {
    try {
      await context
          .read<DashboardViewModel>()
          .loadDashboard();
    } catch (e) {
      debugPrint(
        'Dashboard refresh error: $e',
      );
    }

    await _checkTodayAttendance();

    await _loadMonthlyAttendance();
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final auth =
    context.watch<AuthViewModel>();

    final user = auth.user;

    final employee =
    user?['employee'];

    final employeeNo =
        employee?['employee_no']?.toString() ??
            '-';

    final jobTitle =
        employee?['job_title']?.toString() ??
            'Employee';

    final name =
        user?['name']?.toString() ??
            'User';

    final department =
        employee?['department']?['name']
            ?.toString() ??
            '';

    final unit =
        employee?['unit']?['name']
            ?.toString() ??
            '';

    return Scaffold(
      backgroundColor:
      const Color(0xffF5F7FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
        AppColors.primary,

        foregroundColor:
        Colors.white,

        elevation: 0,

        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
            'Notifications',

            icon: const Icon(
              Icons.notifications_none,
            ),

            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                  const NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),

      // ========================================================
      // DRAWER
      // ========================================================

      drawer: _buildDrawer(
        context,
        name: name,
        employeeNo: employeeNo,
        jobTitle: jobTitle,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh:
        _refreshDashboard,

        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // ==================================================
              // WELCOME CARD
              // ==================================================

              _buildWelcomeCard(
                name: name,
                employeeNo: employeeNo,
                jobTitle: jobTitle,
                department: department,
                unit: unit,
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // TODAY'S ATTENDANCE
              // ==================================================

              _sectionTitle(
                'Today\'s Attendance',
              ),

              const SizedBox(
                height: 10,
              ),

              _buildAttendanceCard(),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // QUICK ACTIONS
              // ==================================================

              _sectionTitle(
                'Quick Actions',
              ),

              const SizedBox(
                height: 10,
              ),

              _buildQuickActions(
                context,
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // MONTHLY SUMMARY
              // ==================================================

              _sectionTitle(
                'This Month',
              ),

              const SizedBox(
                height: 10,
              ),

              _buildMonthlySummary(),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // INFORMATION
              // ==================================================

              _buildInfoCard(),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // WELCOME CARD
  // ==========================================================

  Widget _buildWelcomeCard({
    required String name,
    required String employeeNo,
    required String jobTitle,
    required String department,
    required String unit,
  }) {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
        AppColors.primary,

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.center,

        children: [
          // ----------------------------------------------------
          // PROFILE ICON
          // ----------------------------------------------------

          Container(
            width: 58,
            height: 58,

            decoration:
            BoxDecoration(
              color:
              Colors.white.withValues(
                alpha: .15,
              ),

              shape:
              BoxShape.circle,
            ),

            child: const Icon(
              Icons.person,
              color:
              Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          // ----------------------------------------------------
          // USER INFORMATION
          // ----------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  _greeting(),

                  style:
                  TextStyle(
                    color:
                    Colors.white.withValues(
                      alpha: .85,
                    ),

                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  name,

                  maxLines: 1,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  const TextStyle(
                    color:
                    Colors.white,

                    fontSize: 21,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  '$employeeNo • $jobTitle',

                  maxLines: 2,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  TextStyle(
                    color:
                    Colors.white.withValues(
                      alpha: .9,
                    ),

                    fontSize: 12,
                  ),
                ),

                if (department.isNotEmpty ||
                    unit.isNotEmpty) ...[
                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    [
                      if (department.isNotEmpty)
                        department,
                      if (unit.isNotEmpty)
                        unit,
                    ].join(' • '),

                    maxLines: 2,

                    overflow:
                    TextOverflow.ellipsis,

                    style:
                    TextStyle(
                      color:
                      Colors.white.withValues(
                        alpha: .8,
                      ),

                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ATTENDANCE CARD
  // ==========================================================

  Widget _buildAttendanceCard() {
    final statusColor =
    hasCheckedInToday
        ? Colors.green
        : Colors.orange;

    final statusBackground =
    hasCheckedInToday
        ? Colors.green.withValues(
      alpha: .10,
    )
        : Colors.orange.withValues(
      alpha: .10,
    );

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: .04,
            ),

            blurRadius: 10,

            offset:
            const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          // ====================================================
          // TODAY + STATUS
          // ====================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,

            children: [
              const Expanded(
                child: Text(
                  'Today',

                  style:
                  TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              Flexible(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),

                  decoration:
                  BoxDecoration(
                    color:
                    statusBackground,

                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      Icon(
                        hasCheckedInToday
                            ? Icons.check_circle
                            : Icons
                            .warning_amber_rounded,

                        size: 14,

                        color:
                        statusColor,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Flexible(
                        child: Text(
                          hasCheckedInToday
                              ? 'Checked In'
                              : 'Not Checked In',

                          maxLines: 1,

                          overflow:
                          TextOverflow.ellipsis,

                          style:
                          TextStyle(
                            color:
                            statusColor,

                            fontSize: 11,

                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // CHECK IN / CHECK OUT
          // ====================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Expanded(
                child: _timeCard(
                  icon:
                  Icons.login,

                  title:
                  'Check In',

                  time:
                  hasCheckedInToday
                      ? 'Completed'
                      : '--:--',
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: _timeCard(
                  icon:
                  Icons.logout,

                  title:
                  'Check Out',

                  time:
                  hasCheckedOutToday
                      ? 'Completed'
                      : '--:--',

                  onTap:
                  hasCheckedInToday &&
                      !hasCheckedOutToday
                      ? () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const CheckOutPage(),
                      ),
                    );

                    if (!mounted) {
                      return;
                    }

                    await _checkTodayAttendance();

                    await _loadMonthlyAttendance();
                  }
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // CHECK IN BUTTON
          // ====================================================

          SizedBox(
            width:
            double.infinity,

            height: 52,

            child:
            ElevatedButton.icon(
              onPressed:
              hasCheckedInToday
                  ? null
                  : () async {
                await Navigator.of(
                  context,
                ).push(
                  MaterialPageRoute(
                    builder: (_) =>
                    const AttendancePage(),
                  ),
                );

                if (!mounted) {
                  return;
                }

                await _checkTodayAttendance();

                await _loadMonthlyAttendance();
              },

              icon:
              const Icon(
                Icons.login,
              ),

              label:
              Text(
                hasCheckedInToday
                    ? 'CHECKED IN'
                    : 'CHECK IN',

                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                AppColors.primary,

                foregroundColor:
                Colors.white,

                disabledBackgroundColor:
                Colors.grey.shade300,

                disabledForegroundColor:
                Colors.grey.shade600,

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TIME CARD
  // ==========================================================

  Widget _timeCard({
    required IconData icon,
    required String title,
    required String time,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
      BorderRadius.circular(16),

      child: Container(
        width:
        double.infinity,

        padding:
        const EdgeInsets.all(14),

        decoration:
        BoxDecoration(
          color:
          Colors.white,

          borderRadius:
          BorderRadius.circular(16),

          border:
          Border.all(
            color:
            Colors.grey.shade300,
          ),
        ),

        child: Row(
          children: [
            // --------------------------------------------------
            // ICON
            // --------------------------------------------------

            Container(
              width: 42,
              height: 42,

              decoration:
              BoxDecoration(
                color:
                Colors.grey.shade100,

                shape:
                BoxShape.circle,
              ),

              child: Icon(
                icon,

                size: 22,

                color:
                AppColors.primary,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            // --------------------------------------------------
            // TEXT
            // --------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    maxLines: 1,

                    overflow:
                    TextOverflow.ellipsis,

                    style:
                    const TextStyle(
                      fontSize: 13,

                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    time,

                    maxLines: 1,

                    overflow:
                    TextOverflow.ellipsis,

                    style:
                    TextStyle(
                      fontSize: 16,

                      fontWeight:
                      FontWeight.bold,

                      color:
                      Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // ARROW
            // --------------------------------------------------

            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,

                size: 13,

                color:
                Colors.grey.shade500,
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // QUICK ACTIONS
  // ==========================================================

  Widget _buildQuickActions(
      BuildContext context,
      ) {
    final width =
        MediaQuery.of(context).size.width;

    int crossAxisCount;

    if (width >= 1000) {
      crossAxisCount = 4;
    } else if (width >= 650) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    final childAspectRatio =
    width < 380
        ? 1.15
        : 1.35;

    return GridView.count(
      crossAxisCount:
      crossAxisCount,

      shrinkWrap: true,

      physics:
      const NeverScrollableScrollPhysics(),

      mainAxisSpacing:
      12,

      crossAxisSpacing:
      12,

      childAspectRatio:
      childAspectRatio,

      children: [
        // ----------------------------------------------------
        // MY ATTENDANCE
        // ----------------------------------------------------

        _actionCard(
          icon:
          Icons.access_time,

          title:
          'My Attendance',

          subtitle:
          'Check in / out',

          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                const MyAttendancePage(),
              ),
            );
          },
        ),

        // ----------------------------------------------------
        // HISTORY
        // ----------------------------------------------------

        _actionCard(
          icon:
          Icons.history,

          title:
          'Attendance History',

          subtitle:
          'View records',

          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                const AttendanceHistoryPage(),
              ),
            );
          },
        ),

        // ----------------------------------------------------
        // SCHEDULE
        // ----------------------------------------------------

        _actionCard(
          icon:
          Icons.calendar_month,

          title:
          'My Schedule',

          subtitle:
          'Working schedule',

          onTap: () {
            // TODO:
            // My Schedule Page
          },
        ),

        // ----------------------------------------------------
        // PROFILE
        // ----------------------------------------------------

        _actionCard(
          icon:
          Icons.person_outline,

          title:
          'My Profile',

          subtitle:
          'Employee details',

          onTap: () {
            // TODO:
            // My Profile Page
          },
        ),

        // ----------------------------------------------------
        // REQUESTS
        // ----------------------------------------------------

        _actionCard(
          icon:
          Icons.description_outlined,

          title:
          'My Requests',

          subtitle:
          'Leave & requests',

          onTap: () {
            // TODO:
            // My Requests Page
          },
        ),

        // ----------------------------------------------------
        // NOTIFICATIONS
        // ----------------------------------------------------

        _actionCard(
          icon:
          Icons.notifications_none,

          title:
          'Notifications',

          subtitle:
          'View notifications',

          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                const NotificationsPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================================
  // ACTION CARD
  // ==========================================================

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
      BorderRadius.circular(16),

      child: Container(
        padding:
        const EdgeInsets.all(14),

        decoration:
        BoxDecoration(
          color:
          Colors.white,

          borderRadius:
          BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withValues(
                alpha: .04,
              ),

              blurRadius: 8,

              offset:
              const Offset(0, 3),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Icon(
              icon,

              color:
              AppColors.primary,

              size: 28,
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              title,

              maxLines: 1,

              overflow:
              TextOverflow.ellipsis,

              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,

                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              subtitle,

              maxLines: 1,

              overflow:
              TextOverflow.ellipsis,

              style:
              const TextStyle(
                color:
                Colors.grey,

                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MONTHLY SUMMARY
  // ==========================================================

  Widget _buildMonthlySummary() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Expanded(
          child: _summaryCard(
            title:
            'Present',

            value:
            monthlyPresent.toString(),

            icon:
            Icons.check_circle_outline,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: _summaryCard(
            title:
            'Late',

            value:
            monthlyLate.toString(),

            icon:
            Icons.schedule,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: _summaryCard(
            title:
            'Absent',

            value:
            monthlyAbsent.toString(),

            icon:
            Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SUMMARY CARD
  // ==========================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(15),
      ),

      child: Column(
        children: [
          Icon(
            icon,

            color:
            AppColors.primary,

            size: 25,
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            value,

            style:
            const TextStyle(
              fontSize: 20,

              fontWeight:
              FontWeight.bold,
            ),
          ),

          Text(
            title,

            maxLines: 1,

            overflow:
            TextOverflow.ellipsis,

            style:
            const TextStyle(
              color:
              Colors.grey,

              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFO CARD
  // ==========================================================

  Widget _buildInfoCard() {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets.all(16),

      decoration:
      BoxDecoration(
        color:
        AppColors.primary.withValues(
          alpha: .07,
        ),

        borderRadius:
        BorderRadius.circular(16),
      ),

      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.info_outline,

            color:
            AppColors.primary,
          ),

          SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              'Remember to check in when you arrive at work and check out when you leave.',

              style:
              TextStyle(
                fontSize: 12,

                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _sectionTitle(
      String title,
      ) {
    return Text(
      title,

      style:
      const TextStyle(
        fontSize: 17,

        fontWeight:
        FontWeight.bold,
      ),
    );
  }

  // ==========================================================
  // DRAWER
  // ==========================================================

  Drawer _buildDrawer(
      BuildContext context, {
        required String name,
        required String employeeNo,
        required String jobTitle,
      }) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // DRAWER HEADER
            // ==================================================

            Container(
              width:
              double.infinity,

              padding:
              const EdgeInsets.all(20),

              color:
              AppColors.primary,

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  const CircleAvatar(
                    radius: 30,

                    backgroundColor:
                    Colors.white,

                    child: Icon(
                      Icons.person,

                      color:
                      AppColors.primary,

                      size: 32,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    name,

                    maxLines: 1,

                    overflow:
                    TextOverflow.ellipsis,

                    style:
                    const TextStyle(
                      color:
                      Colors.white,

                      fontSize: 18,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    employeeNo,

                    style:
                    TextStyle(
                      color:
                      Colors.white.withValues(
                        alpha: .85,
                      ),

                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    jobTitle,

                    maxLines: 2,

                    overflow:
                    TextOverflow.ellipsis,

                    style:
                    TextStyle(
                      color:
                      Colors.white.withValues(
                        alpha: .85,
                      ),

                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // DRAWER MENU
            // ==================================================

            Expanded(
              child: ListView(
                padding:
                EdgeInsets.zero,

                children: [
                  // --------------------------------------------
                  // DASHBOARD
                  // --------------------------------------------

                  _drawerItem(
                    icon:
                    Icons.dashboard_outlined,

                    title:
                    'Dashboard',

                    selected:
                    true,

                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                    },
                  ),

                  // --------------------------------------------
                  // ATTENDANCE
                  // --------------------------------------------

                  _drawerItem(
                    icon:
                    Icons.access_time,

                    title:
                    'Attendance',

                    onTap: () async {
                      Navigator.pop(
                        context,
                      );

                      await Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder: (_) =>
                          const AttendancePage(),
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      await _checkTodayAttendance();

                      await _loadMonthlyAttendance();
                    },
                  ),

                  // --------------------------------------------
                  // CHECK OUT
                  // --------------------------------------------

                  _drawerItem(
                    icon:
                    Icons.logout,

                    title:
                    'Check Out',

                    onTap: () async {
                      Navigator.pop(
                        context,
                      );

                      if (!hasCheckedInToday) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please check in first before checking out.',
                            ),

                            backgroundColor:
                            Colors.orange,
                          ),
                        );

                        return;
                      }

                      if (hasCheckedOutToday) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You have already checked out today.',
                            ),

                            backgroundColor:
                            Colors.orange,
                          ),
                        );

                        return;
                      }

                      await Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder: (_) =>
                          const CheckOutPage(),
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      await _checkTodayAttendance();

                      await _loadMonthlyAttendance();
                    },
                  ),

                  // --------------------------------------------
                  // HISTORY
                  // --------------------------------------------

                  _drawerItem(
                    icon:
                    Icons.history,

                    title:
                    'Attendance History',

                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder: (_) =>
                          const AttendanceHistoryPage(),
                        ),
                      );
                    },
                  ),

                  // --------------------------------------------
                  // SCHEDULE
                  // --------------------------------------------

                  _drawerItem(
                    icon:
                    Icons.calendar_month,

                    title:
                    'My Schedule',

                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      // TODO:
                      // My Schedule
                    },
                  ),

                  // --------------------------------------------
                  // REQUESTS
                  // --------------------------------------------

                  _drawerItem(
                    icon:
                    Icons.description_outlined,

                    title:
                    'My Requests',

                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      // TODO:
                      // My Requests
                    },
                  ),

                  // --------------------------------------------
                  // PROFILE
                  // --------------------------------------------

                  _drawerItem(
                    icon:
                    Icons.person_outline,

                    title:
                    'My Profile',

                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      // TODO:
                      // My Profile
                    },
                  ),

                  // --------------------------------------------
                  // NOTIFICATIONS
                  // --------------------------------------------

                  _drawerItem(
                    icon:
                    Icons.notifications_none,

                    title:
                    'Notifications',

                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder: (_) =>
                          const NotificationsPage(),
                        ),
                      );
                    },
                  ),

                  const Divider(),

                  // --------------------------------------------
                  // HELP
                  // --------------------------------------------

                  _drawerItem(
                    icon:
                    Icons.help_outline,

                    title:
                    'Help & Support',

                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      // TODO:
                      // Help & Support
                    },
                  ),
                ],
              ),
            ),

            // ==================================================
            // LOGOUT
            // ==================================================

            const Divider(),

            ListTile(
              leading:
              const Icon(
                Icons.logout,
                color:
                Colors.red,
              ),

              title:
              const Text(
                'Logout',

                style:
                TextStyle(
                  color:
                  Colors.red,

                  fontWeight:
                  FontWeight.w600,
                ),
              ),

              onTap: () async {
                Navigator.of(
                  context,
                ).pop();

                await context
                    .read<AuthViewModel>()
                    .logout();

                if (!context.mounted) {
                  return;
                }

                Navigator.of(
                  context,
                ).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) =>
                    const LoginPage(),
                  ),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DRAWER ITEM
  // ==========================================================

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      leading:
      Icon(
        icon,

        color: selected
            ? AppColors.primary
            : Colors.grey.shade700,
      ),

      title:
      Text(
        title,

        style:
        TextStyle(
          color: selected
              ? AppColors.primary
              : Colors.grey.shade800,

          fontWeight: selected
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),

      selected:
      selected,

      selectedTileColor:
      AppColors.primary.withValues(
        alpha: .08,
      ),

      onTap:
      onTap,
    );
  }

  // ==========================================================
  // GREETING
  // ==========================================================

  String _greeting() {
    final hour =
        DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    }

    if (hour < 17) {
      return 'Good Afternoon';
    }

    return 'Good Evening';
  }
}