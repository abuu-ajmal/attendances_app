import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/attendance.dart';
import '../../repositories/attendance_repository.dart';
import '../../services/storage_service.dart';

class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceHistoryViewModel(),
      child: const _AttendanceHistoryContent(),
    );
  }
}

class _AttendanceHistoryContent extends StatefulWidget {
  const _AttendanceHistoryContent();

  @override
  State<_AttendanceHistoryContent> createState() =>
      _AttendanceHistoryContentState();
}

class _AttendanceHistoryContentState
    extends State<_AttendanceHistoryContent> {
  @override
  Widget build(BuildContext context) {
    final viewModel =
    context.watch<AttendanceHistoryViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: const Text(
          'Attendance History',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: viewModel.isLoading
                ? null
                : viewModel.loadAttendance,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.loadAttendance,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet =
                constraints.maxWidth >= 700;

            return SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 16,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 18),

                      _buildFilterCard(
                        context,
                        viewModel,
                        isTablet,
                      ),

                      const SizedBox(height: 20),

                      _buildSummary(viewModel),

                      const SizedBox(height: 20),

                      if (viewModel.isLoading)
                        const Padding(
                          padding:
                          EdgeInsets.only(top: 50),
                          child: Center(
                            child:
                            CircularProgressIndicator(),
                          ),
                        )
                      else if (
                      viewModel.errorMessage != null)
                        _buildError(viewModel)
                      else if (
                        viewModel.records.isEmpty)
                          _buildEmptyState()
                        else
                          _buildAttendanceList(
                            viewModel,
                            isTablet,
                          ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'View and track your attendance records.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF687386),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  Widget _buildFilterCard(
      BuildContext context,
      AttendanceHistoryViewModel viewModel,
      bool isTablet,
      ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isTablet ? 22 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E9F0),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: 20,
                color: Color(0xFF087F5B),
              ),
              SizedBox(width: 8),
              Text(
                'Filter Attendance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172033),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: _dateField(
                    context,
                    label: 'From Date',
                    date:
                    viewModel.fromDate,
                    onTap: () =>
                        viewModel.pickFromDate(
                          context,
                        ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _dateField(
                    context,
                    label: 'To Date',
                    date:
                    viewModel.toDate,
                    onTap: () =>
                        viewModel.pickToDate(
                          context,
                        ),
                  ),
                ),

                const SizedBox(width: 14),

                SizedBox(
                  height: 52,
                  child:
                  ElevatedButton.icon(
                    onPressed:
                    viewModel.isLoading
                        ? null
                        : viewModel
                        .loadAttendance,
                    icon:
                    const Icon(Icons.search),
                    label:
                    const Text('Apply'),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xFF087F5B,
                      ),
                      foregroundColor:
                      Colors.white,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 22,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _dateField(
                  context,
                  label: 'From Date',
                  date:
                  viewModel.fromDate,
                  onTap: () =>
                      viewModel.pickFromDate(
                        context,
                      ),
                ),

                const SizedBox(height: 12),

                _dateField(
                  context,
                  label: 'To Date',
                  date:
                  viewModel.toDate,
                  onTap: () =>
                      viewModel.pickToDate(
                        context,
                      ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child:
                  ElevatedButton.icon(
                    onPressed:
                    viewModel.isLoading
                        ? null
                        : viewModel
                        .loadAttendance,
                    icon:
                    const Icon(Icons.search),
                    label:
                    const Text(
                      'Apply Filter',
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xFF087F5B,
                      ),
                      foregroundColor:
                      Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          Align(
            alignment:
            Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
              viewModel.isLoading
                  ? null
                  : viewModel.clearFilter,
              icon:
              const Icon(Icons.clear),
              label:
              const Text('Clear Filter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(
      BuildContext context, {
        required String label,
        required DateTime? date,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color:
          const Color(0xFFF8FAFC),
          borderRadius:
          BorderRadius.circular(12),
          border: Border.all(
            color:
            const Color(0xFFDCE2EA),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 19,
              color: Color(0xFF687386),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                    const TextStyle(
                      fontSize: 11,
                      color:
                      Color(0xFF7B8494),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date == null
                        ? 'Select date'
                        : DateFormat(
                      'dd MMM yyyy',
                    ).format(date),
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Color(0xFF172033),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
      AttendanceHistoryViewModel viewModel,
      ) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Check In',
            value:
            viewModel.checkInCount
                .toString(),
            icon: Icons.login,
            iconColor:
            const Color(0xFF087F5B),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _summaryCard(
            title: 'Check Out',
            value:
            viewModel.checkOutCount
                .toString(),
            icon: Icons.logout,
            iconColor:
            const Color(0xFF2563EB),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _summaryCard(
            title: 'Records',
            value:
            viewModel.records.length
                .toString(),
            icon:
            Icons.fact_check_outlined,
            iconColor:
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE5E9F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
            BoxDecoration(
              color:
              iconColor.withOpacity(
                0.10,
              ),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 19,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style:
            const TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style:
            const TextStyle(
              fontSize: 12,
              color:
              Color(0xFF687386),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIST
  // ============================================================

  Widget _buildAttendanceList(
      AttendanceHistoryViewModel viewModel,
      bool isTablet,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Records',
          style: TextStyle(
            fontSize: 17,
            fontWeight:
            FontWeight.w800,
            color:
            Color(0xFF172033),
          ),
        ),

        const SizedBox(height: 12),

        ...viewModel.records.map(
              (attendance) =>
              _attendanceCard(
                attendance,
                isTablet,
              ),
        ),
      ],
    );
  }

  Widget _attendanceCard(
      Attendance attendance,
      bool isTablet,
      ) {
    final String type =
        attendance.type?.toLowerCase() ??
            '';

    final bool isCheckIn =
        type == 'check_in';

    final String occurredAt =
        attendance.occurredAt ?? '';

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      padding: EdgeInsets.all(
        isTablet ? 18 : 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color:
          const Color(0xFFE5E9F0),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.025,
            ),
            blurRadius: 10,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  color: isCheckIn
                      ? const Color(
                    0xFFE8F7F1,
                  )
                      : const Color(
                    0xFFEAF1FF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  isCheckIn
                      ? Icons.login
                      : Icons.logout,
                  color: isCheckIn
                      ? const Color(
                    0xFF087F5B,
                  )
                      : const Color(
                    0xFF2563EB,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckIn
                          ? 'Check In'
                          : 'Check Out',
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _formatDateTime(
                        occurredAt,
                      ),
                      style:
                      const TextStyle(
                        fontSize: 13,
                        color:
                        Color(0xFF687386),
                      ),
                    ),
                  ],
                ),
              ),

              _statusBadge(
                isCheckIn
                    ? 'CHECK IN'
                    : 'CHECK OUT',
                isCheckIn,
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(
            height: 1,
            color:
            Color(0xFFECEFF3),
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon:
                  Icons.access_time,
                  title: 'Time',
                  value:
                  _formatTime(
                    occurredAt,
                  ),
                ),
              ),

              Expanded(
                child: _infoItem(
                  icon: Icons
                      .location_on_outlined,
                  title: 'Location',
                  value:
                  _locationText(
                    attendance,
                  ),
                ),
              ),

              Expanded(
                child: _infoItem(
                  icon: Icons
                      .photo_camera_outlined,
                  title: 'Photo',
                  value:
                  _hasPhoto(
                    attendance,
                  )
                      ? 'Available'
                      : 'No photo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color:
          const Color(0xFF7B8494),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                const TextStyle(
                  fontSize: 10,
                  color:
                  Color(0xFF8A93A1),
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xFF172033),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(
      String text,
      bool isCheckIn,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color: isCheckIn
            ? const Color(0xFFE8F7F1)
            : const Color(0xFFEAF1FF),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight:
          FontWeight.w800,
          color: isCheckIn
              ? const Color(0xFF087F5B)
              : const Color(0xFF2563EB),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 55,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE5E9F0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 58,
            color:
            Color(0xFF9AA3B2),
          ),

          SizedBox(height: 14),

          Text(
            'No attendance records',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF172033),
            ),
          ),

          SizedBox(height: 7),

          Text(
            'There are no attendance records for the selected period.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color:
              Color(0xFF687386),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(
      AttendanceHistoryViewModel viewModel,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
        const Color(0xFFFFF5F5),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 42,
            color:
            Color(0xFFDC2626),
          ),

          const SizedBox(height: 10),

          Text(
            viewModel.errorMessage ??
                'Failed to load attendance.',
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              Color(0xFF991B1B),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed:
            viewModel.loadAttendance,
            icon:
            const Icon(Icons.refresh),
            label:
            const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDateTime(
      String? value,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return '--';
    }

    try {
      final date =
      DateTime.parse(value).toLocal();

      return DateFormat(
        'dd MMM yyyy, HH:mm',
      ).format(date);
    } catch (_) {
      return value;
    }
  }

  String _formatTime(
      String? value,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return '--:--';
    }

    try {
      final date =
      DateTime.parse(value).toLocal();

      return DateFormat(
        'HH:mm',
      ).format(date);
    } catch (_) {
      return '--:--';
    }
  }

  String _locationText(
      Attendance attendance,
      ) {
    final latitude =
        attendance.latitude;

    final longitude =
        attendance.longitude;

    if (latitude == null ||
        longitude == null) {
      return 'Unavailable';
    }

    return '${latitude.toStringAsFixed(4)}, '
        '${longitude.toStringAsFixed(4)}';
  }

  bool _hasPhoto(
      Attendance attendance,
      ) {
    final photo =
        attendance.photoPath;

    return photo != null &&
        photo.trim().isNotEmpty;
  }
}

// ================================================================
// VIEW MODEL
// ================================================================

class AttendanceHistoryViewModel
    extends ChangeNotifier {
  AttendanceHistoryViewModel({
    AttendanceRepository? repository,
    StorageService? storageService,
  })  : _repository =
      repository ??
          AttendanceRepository(),
        _storageService =
            storageService ??
                StorageService.instance {
    _setDefaultDates();
    loadAttendance();
  }

  final AttendanceRepository _repository;

  final StorageService _storageService;

  bool _isLoading = false;

  String? _errorMessage;

  List<Attendance> _records = [];

  DateTime? _fromDate;

  DateTime? _toDate;

  bool get isLoading => _isLoading;

  String? get errorMessage =>
      _errorMessage;

  List<Attendance> get records =>
      _records;

  DateTime? get fromDate =>
      _fromDate;

  DateTime? get toDate =>
      _toDate;

  // ============================================================
  // CHECK IN COUNT
  // ============================================================

  int get checkInCount {
    return _records.where(
          (item) =>
      item.type?.toLowerCase() ==
          'check_in',
    ).length;
  }

  // ============================================================
  // CHECK OUT COUNT
  // ============================================================

  int get checkOutCount {
    return _records.where(
          (item) =>
      item.type?.toLowerCase() ==
          'check_out',
    ).length;
  }

  // ============================================================
  // SET DEFAULT DATES
  // ============================================================

  void _setDefaultDates() {
    final now =
    DateTime.now();

    _fromDate = DateTime(
      now.year,
      now.month,
      1,
    );

    _toDate = DateTime(
      now.year,
      now.month + 1,
      0,
    );
  }

  // ============================================================
  // GET EMPLOYEE ID
  // ============================================================

  Future<int?> _getEmployeeId() async {
    try {
      final user =
      await _storageService.getUser();

      if (user == null) {
        return null;
      }

      final employeeId =
      _extractEmployeeId(user);

      if (employeeId == null ||
          employeeId <= 0) {
        return null;
      }

      return employeeId;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // EXTRACT EMPLOYEE ID
  // ============================================================

  int? _extractEmployeeId(
      dynamic user,
      ) {
    if (user is! Map) {
      return null;
    }

    // ----------------------------------------------------------
    // user['employee_id']
    // ----------------------------------------------------------

    final directEmployeeId =
    _parseInt(
      user['employee_id'],
    );

    if (directEmployeeId != null &&
        directEmployeeId > 0) {
      return directEmployeeId;
    }

    // ----------------------------------------------------------
    // user['employee']['id']
    // ----------------------------------------------------------

    final employee =
    user['employee'];

    if (employee is Map) {
      final employeeId =
      _parseInt(
        employee['id'],
      );

      if (employeeId != null &&
          employeeId > 0) {
        return employeeId;
      }
    }

    // ----------------------------------------------------------
    // user['data']
    // ----------------------------------------------------------

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

      // --------------------------------------------------------
      // user['data']['employee']['id']
      // --------------------------------------------------------

      final dataEmployee =
      data['employee'];

      if (dataEmployee is Map) {
        final employeeId =
        _parseInt(
          dataEmployee['id'],
        );

        if (employeeId != null &&
            employeeId > 0) {
          return employeeId;
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

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // LOAD ATTENDANCE
  // ============================================================

  Future<void> loadAttendance() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // --------------------------------------------------------
      // GET CURRENT EMPLOYEE
      // --------------------------------------------------------

      final employeeId =
      await _getEmployeeId();

      if (employeeId == null ||
          employeeId <= 0) {
        _records = [];

        _errorMessage =
        'Employee ID haijapatikana. Tafadhali login tena.';

        return;
      }

      // --------------------------------------------------------
      // GET ATTENDANCE
      // --------------------------------------------------------

      final records =
      await _repository.getMyAttendance(
        employeeId: employeeId,
        from:
        _formatApiDate(_fromDate),
        to:
        _formatApiDate(_toDate),
        perPage: 100,
      );

      // --------------------------------------------------------
      // SORT NEWEST FIRST
      // --------------------------------------------------------

      records.sort(
            (a, b) {
          final aDate =
          _parseDate(
            a.occurredAt,
          );

          final bDate =
          _parseDate(
            b.occurredAt,
          );

          if (aDate == null &&
              bDate == null) {
            return 0;
          }

          if (aDate == null) {
            return 1;
          }

          if (bDate == null) {
            return -1;
          }

          return bDate.compareTo(
            aDate,
          );
        },
      );

      _records = records;
    } catch (e) {
      _records = [];

      _errorMessage =
          e.toString().replaceFirst(
            'Exception: ',
            '',
          );
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime? _parseDate(
      String? value,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // PICK FROM DATE
  // ============================================================

  Future<void> pickFromDate(
      BuildContext context,
      ) async {
    final selected =
    await showDatePicker(
      context: context,
      initialDate:
      _fromDate ??
          DateTime.now(),
      firstDate:
      DateTime(2020),
      lastDate:
      DateTime.now(),
    );

    if (selected == null) {
      return;
    }

    _fromDate = selected;

    if (_toDate != null &&
        _fromDate!.isAfter(
          _toDate!,
        )) {
      _toDate = _fromDate;
    }

    notifyListeners();
  }

  // ============================================================
  // PICK TO DATE
  // ============================================================

  Future<void> pickToDate(
      BuildContext context,
      ) async {
    final selected =
    await showDatePicker(
      context: context,
      initialDate:
      _toDate ??
          DateTime.now(),
      firstDate:
      _fromDate ??
          DateTime(2020),
      lastDate:
      DateTime.now(),
    );

    if (selected == null) {
      return;
    }

    _toDate = selected;

    notifyListeners();
  }

  // ============================================================
  // CLEAR FILTER
  // ============================================================

  void clearFilter() {
    _setDefaultDates();

    loadAttendance();
  }

  // ============================================================
  // FORMAT API DATE
  // ============================================================

  String? _formatApiDate(
      DateTime? date,
      ) {
    if (date == null) {
      return null;
    }

    return DateFormat(
      'yyyy-MM-dd',
    ).format(date);
  }
}