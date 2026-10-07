
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attendance_warning.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/notification_view_model.dart';
import 'warning_letter_page.dart';

class NotificationsPage extends StatefulWidget {
const NotificationsPage({
super.key,
});

@override
State<NotificationsPage> createState() =>
_NotificationsPageState();
}

class _NotificationsPageState
extends State<NotificationsPage> {
@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
if (!mounted) return;

context
    .read<NotificationViewModel>()
    .loadNotifications();
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xffF5F7FA),

appBar: AppBar(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
elevation: 0,

title: const Text(
'Notifications',
style: TextStyle(
fontWeight: FontWeight.w700,
),
),

actions: [
IconButton(
tooltip: 'Refresh',
onPressed: () {
context
    .read<NotificationViewModel>()
    .refresh();
},
icon: const Icon(
Icons.refresh,
),
),
],
),

body: Consumer<NotificationViewModel>(
builder: (
context,
viewModel,
child,
) {
// ==================================================
// LOADING
// ==================================================

if (viewModel.isLoading &&
viewModel.warning == null) {
return const Center(
child: CircularProgressIndicator(),
);
}

// ==================================================
// ERROR
// ==================================================

if (viewModel.hasError &&
viewModel.warning == null) {
return _buildErrorState(
context,
viewModel.errorMessage!,
);
}

final warning = viewModel.warning;

// ==================================================
// EMPTY
// ==================================================

if (warning == null) {
return _buildEmptyState();
}

// ==================================================
// CONTENT
// ==================================================

return RefreshIndicator(
onRefresh: viewModel.refresh,

child: ListView(
physics:
const AlwaysScrollableScrollPhysics(),

padding:
const EdgeInsets.all(16),

children: [
_buildHeader(
warning,
),

const SizedBox(
height: 16,
),

if (warning.hasWarning)
_buildWarningCard(
warning,
)
else
_buildNoWarningCard(
warning,
),

const SizedBox(
height: 16,
),

_buildSummaryCard(
warning,
),

const SizedBox(
height: 16,
),

_buildLateRecords(
warning,
),

const SizedBox(
height: 16,
),

_buildInformationCard(
warning,
),

const SizedBox(
height: 30,
),
],
),
);
},
),
);
}

// ==========================================================
// HEADER
// ==========================================================

Widget _buildHeader(
AttendanceWarning warning,
) {
final employee = warning.employee;

return Container(
width: double.infinity,

padding:
const EdgeInsets.all(20),

decoration: BoxDecoration(
color: AppColors.primary,

borderRadius:
BorderRadius.circular(20),

boxShadow: [
BoxShadow(
color: Colors.black.withValues(
alpha: .05,
),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),

child: Row(
children: [
Container(
width: 58,
height: 58,

decoration: BoxDecoration(
color:
Colors.white.withValues(
alpha: .15,
),
shape: BoxShape.circle,
),

child: const Icon(
Icons.person,
color: Colors.white,
size: 32,
),
),

const SizedBox(
width: 14,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
const Text(
'Attendance Notifications',
style: TextStyle(
color: Colors.white,
fontSize: 13,
),
),

const SizedBox(
height: 5,
),

Text(
employee.name,

maxLines: 1,

overflow:
TextOverflow.ellipsis,

style: const TextStyle(
color: Colors.white,
fontSize: 19,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 4,
),

Text(
employee.employeeNo,

style: TextStyle(
color:
Colors.white.withValues(
alpha: .85,
),
fontSize: 12,
),
),

if (employee.department
    .isNotEmpty ||
employee.unit.isNotEmpty) ...[
const SizedBox(
height: 3,
),

Text(
[
if (employee.department
    .isNotEmpty)
employee.department,

if (employee.unit
    .isNotEmpty)
employee.unit,
].join(' • '),

maxLines: 2,

overflow:
TextOverflow.ellipsis,

style: TextStyle(
color:
Colors.white.withValues(
alpha: .75,
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
// WARNING CARD
// ==========================================================

Widget _buildWarningCard(
AttendanceWarning warning,
) {
return Container(
width: double.infinity,

padding:
const EdgeInsets.all(18),

decoration: BoxDecoration(
color:
Colors.orange.shade50,

borderRadius:
BorderRadius.circular(18),

border: Border.all(
color:
Colors.orange.shade200,
),
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Row(
children: [
Container(
width: 46,
height: 46,

decoration: BoxDecoration(
color:
Colors.orange.withValues(
alpha: .15,
),
shape: BoxShape.circle,
),

child: const Icon(
Icons.warning_amber_rounded,
color: Colors.orange,
size: 27,
),
),

const SizedBox(
width: 12,
),

const Expanded(
child: Text(
'Attendance Warning',
style: TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
color: Colors.orange,
),
),
),
],
),

const SizedBox(
height: 15,
),

Text(
warning.message ??
'You have reported late for consecutive working days.',

style: const TextStyle(
fontSize: 14,
height: 1.5,
fontWeight:
FontWeight.w500,
),
),

const SizedBox(
height: 15,
),

// ==================================================
// REQUIRED CHECK-IN TIME
// ==================================================

Container(
padding:
const EdgeInsets.all(12),

decoration: BoxDecoration(
color:
Colors.white.withValues(
alpha: .65,
),

borderRadius:
BorderRadius.circular(12),
),

child: Row(
children: [
const Icon(
Icons.info_outline,
color: Colors.orange,
size: 20,
),

const SizedBox(
width: 9,
),

Expanded(
child: Text(
'Required check-in time: '
'${warning.requiredCheckIn}',

style:
const TextStyle(
fontSize: 12,
fontWeight:
FontWeight.w600,
),
),
),
],
),
),

// ==================================================
// OFFICIAL WARNING LETTER
// ==================================================

if (warning.hasWarning) ...[
const SizedBox(
height: 16,
),

_buildWarningLetterButton(),
],
],
),
);
}

// ==========================================================
// OFFICIAL WARNING LETTER BUTTON
// ==========================================================

Widget _buildWarningLetterButton() {
return SizedBox(
width: double.infinity,
height: 52,

child: ElevatedButton.icon(
onPressed: () {
Navigator.of(context).push(
MaterialPageRoute(
builder: (_) =>
const WarningLetterPage(),
),
);
},

icon: const Icon(
Icons.picture_as_pdf_outlined,
size: 22,
),

label: const Text(
'View Official Warning Letter',
style: TextStyle(
fontSize: 13,
fontWeight:
FontWeight.w700,
),
),

style:
ElevatedButton.styleFrom(
backgroundColor:
AppColors.primary,

foregroundColor:
Colors.white,

elevation: 0,

padding:
const EdgeInsets.symmetric(
horizontal: 16,
),

shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),
);
}

// ==========================================================
// NO WARNING
// ==========================================================

Widget _buildNoWarningCard(
AttendanceWarning warning,
) {
return Container(
width: double.infinity,

padding:
const EdgeInsets.all(20),

decoration: BoxDecoration(
color:
Colors.green.shade50,

borderRadius:
BorderRadius.circular(18),

border: Border.all(
color:
Colors.green.shade200,
),
),

child: Row(
children: [
Container(
width: 48,
height: 48,

decoration: BoxDecoration(
color:
Colors.green.withValues(
alpha: .12,
),
shape: BoxShape.circle,
),

child: const Icon(
Icons.check_circle_outline,
color: Colors.green,
size: 28,
),
),

const SizedBox(
width: 13,
),

const Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Text(
'No Attendance Warning',
style: TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
color: Colors.green,
),
),

SizedBox(
height: 5,
),

Text(
'Your recent attendance does not currently meet the warning threshold.',
style: TextStyle(
fontSize: 12,
height: 1.4,
),
),
],
),
),
],
),
);
}

// ==========================================================
// SUMMARY
// ==========================================================

Widget _buildSummaryCard(
AttendanceWarning warning,
) {
return Container(
width: double.infinity,

padding:
const EdgeInsets.all(18),

decoration: BoxDecoration(
color: Colors.white,

borderRadius:
BorderRadius.circular(18),

boxShadow: [
BoxShadow(
color:
Colors.black.withValues(
alpha: .04,
),
blurRadius: 9,
offset:
const Offset(0, 3),
),
],
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
const Text(
'Attendance Summary',
style: TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 15,
),

Row(
children: [
Expanded(
child: _summaryItem(
icon:
Icons.warning_amber_rounded,
value: warning
    .consecutiveLateDays
    .toString(),
title:
'Consecutive Late',
),
),

const SizedBox(
width: 10,
),

Expanded(
child: _summaryItem(
icon:
Icons.flag_outlined,
value:
warning.threshold
    .toString(),
title:
'Warning Threshold',
),
),

const SizedBox(
width: 10,
),

Expanded(
child: _summaryItem(
icon: Icons.login,
value:
warning.requiredCheckIn,
title:
'Required Time',
),
),
],
),
],
),
);
}

Widget _summaryItem({
required IconData icon,
required String value,
required String title,
}) {
return Container(
padding:
const EdgeInsets.symmetric(
vertical: 14,
horizontal: 6,
),

decoration: BoxDecoration(
color:
const Color(0xffF5F7FA),

borderRadius:
BorderRadius.circular(14),
),

child: Column(
children: [
Icon(
icon,
color: AppColors.primary,
size: 23,
),

const SizedBox(
height: 7,
),

Text(
value,

textAlign:
TextAlign.center,

maxLines: 1,

overflow:
TextOverflow.ellipsis,

style: const TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 3,
),

Text(
title,

textAlign:
TextAlign.center,

maxLines: 2,

style: TextStyle(
color:
Colors.grey.shade600,
fontSize: 9,
),
),
],
),
);
}

// ==========================================================
// LATE RECORDS
// ==========================================================

Widget _buildLateRecords(
AttendanceWarning warning,
) {
if (warning.lateRecords.isEmpty) {
return Container(
width: double.infinity,

padding:
const EdgeInsets.all(18),

decoration: BoxDecoration(
color: Colors.white,

borderRadius:
BorderRadius.circular(18),
),

child: const Column(
children: [
Icon(
Icons.event_available,
size: 35,
color: Colors.green,
),

SizedBox(
height: 8,
),

Text(
'No recent late records',
style: TextStyle(
fontWeight:
FontWeight.w600,
),
),
],
),
);
}

return Container(
width: double.infinity,

padding:
const EdgeInsets.all(18),

decoration: BoxDecoration(
color: Colors.white,

borderRadius:
BorderRadius.circular(18),

boxShadow: [
BoxShadow(
color:
Colors.black.withValues(
alpha: .04,
),
blurRadius: 9,
offset:
const Offset(0, 3),
),
],
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
const Text(
'Recent Late Records',
style: TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 12,
),

...warning.lateRecords.map(
(record) =>
_lateRecordItem(
record,
warning.requiredCheckIn,
),
),
],
),
);
}

Widget _lateRecordItem(
LateRecord record,
String requiredTime,
) {
return Container(
margin:
const EdgeInsets.only(
bottom: 10,
),

padding:
const EdgeInsets.all(13),

decoration: BoxDecoration(
color:
Colors.orange.shade50,

borderRadius:
BorderRadius.circular(13),
),

child: Row(
children: [
Container(
width: 42,
height: 42,

decoration: BoxDecoration(
color:
Colors.orange.withValues(
alpha: .12,
),
shape: BoxShape.circle,
),

child: const Icon(
Icons.schedule,
color: Colors.orange,
size: 22,
),
),

const SizedBox(
width: 12,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Text(
_formatDate(
record.date,
),

style:
const TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 13,
),
),

const SizedBox(
height: 4,
),

Text(
'Check-in: ${record.checkIn}',

style: TextStyle(
color:
Colors.grey.shade700,
fontSize: 11,
),
),
],
),
),

Column(
crossAxisAlignment:
CrossAxisAlignment.end,

children: [
Text(
'+${record.minutesLate} min',

style:
const TextStyle(
color: Colors.orange,
fontWeight:
FontWeight.bold,
fontSize: 13,
),
),

const SizedBox(
height: 3,
),

Text(
'after $requiredTime',

style: TextStyle(
color:
Colors.grey.shade600,
fontSize: 9,
),
),
],
),
],
),
);
}

// ==========================================================
// INFORMATION CARD
// ==========================================================

Widget _buildInformationCard(
AttendanceWarning warning,
) {
return Container(
width: double.infinity,

padding:
const EdgeInsets.all(16),

decoration: BoxDecoration(
color:
AppColors.primary.withValues(
alpha: .07,
),

borderRadius:
BorderRadius.circular(16),
),

child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
const Icon(
Icons.info_outline,
color: AppColors.primary,
),

const SizedBox(
width: 12,
),

Expanded(
child: Text(
'Please make sure you check in on time. '
'The required check-in time is '
'${warning.requiredCheckIn}. '
'Weekends are not counted as working days.',

style: const TextStyle(
fontSize: 12,
height: 1.5,
),
),
),
],
),
);
}

// ==========================================================
// ERROR STATE
// ==========================================================

Widget _buildErrorState(
BuildContext context,
String message,
) {
return Center(
child: Padding(
padding:
const EdgeInsets.all(30),

child: Column(
mainAxisAlignment:
MainAxisAlignment.center,

children: [
Container(
width: 72,
height: 72,

decoration: BoxDecoration(
color:
Colors.red.withValues(
alpha: .08,
),
shape: BoxShape.circle,
),

child: const Icon(
Icons.cloud_off_outlined,
color: Colors.red,
size: 36,
),
),

const SizedBox(
height: 16,
),

const Text(
'Unable to load notifications',
textAlign:
TextAlign.center,

style: TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 8,
),

Text(
message,
textAlign:
TextAlign.center,

style: TextStyle(
color:
Colors.grey.shade600,
fontSize: 12,
),
),

const SizedBox(
height: 20,
),

ElevatedButton.icon(
onPressed: () {
context
    .read<
NotificationViewModel>()
    .loadNotifications();
},

icon: const Icon(
Icons.refresh,
),

label: const Text(
'Retry',
),

style:
ElevatedButton.styleFrom(
backgroundColor:
AppColors.primary,
foregroundColor:
Colors.white,
),
),
],
),
),
);
}

// ==========================================================
// EMPTY STATE
// ==========================================================

Widget _buildEmptyState() {
return Center(
child: Padding(
padding:
const EdgeInsets.all(30),

child: Column(
mainAxisAlignment:
MainAxisAlignment.center,

children: [
Icon(
Icons.notifications_none,
size: 70,
color:
Colors.grey.shade400,
),

const SizedBox(
height: 15,
),

const Text(
'No Notifications',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 7,
),

Text(
'You currently have no attendance notifications.',
textAlign:
TextAlign.center,

style: TextStyle(
color:
Colors.grey.shade600,
fontSize: 12,
),
),
],
),
),
);
}

// ==========================================================
// FORMAT DATE
// ==========================================================

String _formatDate(
String value,
) {
final date =
DateTime.tryParse(value);

if (date == null) {
return value;
}

return '${date.day.toString().padLeft(2, '0')}/'
'${date.month.toString().padLeft(2, '0')}/'
'${date.year}';
}
}

