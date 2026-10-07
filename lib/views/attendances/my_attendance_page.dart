
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../models/attendance.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/attendance_view_model.dart';

class MyAttendancePage extends StatelessWidget {
const MyAttendancePage({super.key});

@override
Widget build(BuildContext context) {
return ChangeNotifierProvider(
create: (_) => AttendanceViewModel()
..loadMyAttendance(),
child: const _MyAttendanceContent(),
);
}
}

class _MyAttendanceContent extends StatelessWidget {
const _MyAttendanceContent();

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F7FA),

appBar: AppBar(
elevation: 0,
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,

title: const Text(
'My Attendance',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.w700,
),
),

actions: [
Consumer<AttendanceViewModel>(
builder: (context, viewModel, _) {
return IconButton(
tooltip: 'Refresh',
onPressed: viewModel.isLoadingMyAttendance
? null
    : () {
viewModel.loadMyAttendance();
},
icon: const Icon(
Icons.refresh,
),
);
},
),
],
),

body: SafeArea(
child: Consumer<AttendanceViewModel>(
builder: (
context,
viewModel,
child,
) {
// ==========================================
// LOADING
// ==========================================

if (viewModel.isLoadingMyAttendance &&
viewModel.myAttendances.isEmpty) {
return const Center(
child: CircularProgressIndicator(),
);
}

// ==========================================
// ERROR
// ==========================================

if (viewModel.errorMessage != null &&
viewModel.myAttendances.isEmpty) {
return _buildError(
context,
viewModel,
);
}

// ==========================================
// EMPTY
// ==========================================

if (viewModel.myAttendances.isEmpty) {
return _buildEmpty();
}

// ==========================================
// DATA
// ==========================================

return RefreshIndicator(
color: AppColors.primary,

onRefresh: () {
return viewModel.loadMyAttendance();
},

child: LayoutBuilder(
builder: (
context,
constraints,
) {
final isTablet =
constraints.maxWidth >= 600;

final horizontalPadding =
isTablet ? 32.0 : 16.0;

return ListView(
physics:
const AlwaysScrollableScrollPhysics(),

padding: EdgeInsets.fromLTRB(
horizontalPadding,
16,
horizontalPadding,
30,
),

children: [
// ==================================
// SUMMARY
// ==================================

_buildSummaryCard(
viewModel.myAttendances,
isTablet,
),

const SizedBox(height: 24),

// ==================================
// SECTION TITLE
// ==================================

Row(
children: [
Container(
width: 4,
height: 24,
decoration: BoxDecoration(
color:
AppColors.primary,
borderRadius:
BorderRadius.circular(
10,
),
),
),

const SizedBox(width: 10),

const Expanded(
child: Text(
'Attendance History',
style: TextStyle(
fontSize: 19,
fontWeight:
FontWeight.w800,
),
),
),

Text(
'${viewModel.myAttendances.length} records',
style: const TextStyle(
color: Colors.grey,
fontSize: 12,
fontWeight:
FontWeight.w500,
),
),
],
),

const SizedBox(height: 14),

// ==================================
// RECORDS
// ==================================

...viewModel.myAttendances.map(
(attendance) {
return _AttendanceCard(
attendance:
attendance,
isTablet: isTablet,
);
},
),
],
);
},
),
);
},
),
),
);
}

// =====================================================
// SUMMARY CARD
// =====================================================

Widget _buildSummaryCard(
List<Attendance> attendances,
bool isTablet,
) {
final checkIns = attendances
    .where(
(item) => item.type == 'check_in',
)
    .length;

final checkOuts = attendances
    .where(
(item) => item.type == 'check_out',
)
    .length;

final total = attendances.length;

return Container(
padding: EdgeInsets.all(
isTablet ? 24 : 18,
),

decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
AppColors.primary,
AppColors.primary.withValues(
alpha: 0.82,
),
],
),

borderRadius: BorderRadius.circular(22),

boxShadow: [
BoxShadow(
color: AppColors.primary.withValues(
alpha: 0.18,
),
blurRadius: 18,
offset: const Offset(0, 8),
),
],
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Row(
children: [
Container(
width: 42,
height: 42,

decoration: BoxDecoration(
color: Colors.white.withValues(
alpha: 0.15,
),
borderRadius:
BorderRadius.circular(12),
),

child: const Icon(
Icons.access_time,
color: Colors.white,
),
),

const SizedBox(width: 12),

const Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'My Attendance',
style: TextStyle(
color: Colors.white,
fontSize: 17,
fontWeight:
FontWeight.w800,
),
),
SizedBox(height: 3),
Text(
'Your attendance summary',
style: TextStyle(
color: Colors.white70,
fontSize: 12,
),
),
],
),
),
],
),

const SizedBox(height: 22),

Row(
children: [
Expanded(
child: _SummaryItem(
icon: Icons.login,
title: 'Check In',
value: checkIns.toString(),
),
),

_summaryDivider(),

Expanded(
child: _SummaryItem(
icon: Icons.logout,
title: 'Check Out',
value: checkOuts.toString(),
),
),

_summaryDivider(),

Expanded(
child: _SummaryItem(
icon: Icons.history,
title: 'Total',
value: total.toString(),
),
),
],
),
],
),
);
}

Widget _summaryDivider() {
return Container(
width: 1,
height: 52,
color: Colors.white.withValues(
alpha: 0.22,
),
);
}

// =====================================================
// EMPTY
// =====================================================

Widget _buildEmpty() {
return Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(30),

child: Column(
mainAxisAlignment:
MainAxisAlignment.center,

children: [
Container(
width: 100,
height: 100,

decoration: BoxDecoration(
color: AppColors.primary
    .withValues(alpha: 0.08),
shape: BoxShape.circle,
),

child: Icon(
Icons.access_time_outlined,
size: 52,
color: AppColors.primary,
),
),

const SizedBox(height: 22),

const Text(
'No Attendance Records',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 8),

const Text(
'Your check-in and check-out records '
'will appear here.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.grey,
fontSize: 14,
height: 1.5,
),
),
],
),
),
);
}

// =====================================================
// ERROR
// =====================================================

Widget _buildError(
BuildContext context,
AttendanceViewModel viewModel,
) {
return Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(28),

child: Column(
mainAxisAlignment:
MainAxisAlignment.center,

children: [
Container(
width: 90,
height: 90,

decoration: BoxDecoration(
color: Colors.red.withValues(
alpha: 0.08,
),
shape: BoxShape.circle,
),

child: const Icon(
Icons.cloud_off_outlined,
size: 46,
color: Colors.redAccent,
),
),

const SizedBox(height: 20),

const Text(
'Unable to Load Attendance',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 8),

Text(
viewModel.errorMessage ??
'Something went wrong. '
'Please try again.',
textAlign: TextAlign.center,
style: const TextStyle(
color: Colors.grey,
fontSize: 13,
height: 1.5,
),
),

const SizedBox(height: 22),

ElevatedButton.icon(
onPressed: () {
viewModel.loadMyAttendance();
},

icon: const Icon(
Icons.refresh,
),

label: const Text(
'Try Again',
),

style: ElevatedButton.styleFrom(
backgroundColor:
AppColors.primary,
foregroundColor: Colors.white,

padding:
const EdgeInsets.symmetric(
horizontal: 24,
vertical: 13,
),

shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),
],
),
),
);
}
}

// =======================================================
// SUMMARY ITEM
// =======================================================

class _SummaryItem extends StatelessWidget {
const _SummaryItem({
required this.icon,
required this.title,
required this.value,
});

final IconData icon;
final String title;
final String value;

@override
Widget build(BuildContext context) {
return Column(
children: [
Icon(
icon,
color: Colors.white,
size: 23,
),

const SizedBox(height: 6),

Text(
value,
style: const TextStyle(
color: Colors.white,
fontSize: 22,
fontWeight: FontWeight.w900,
),
),

const SizedBox(height: 2),

Text(
title,
style: const TextStyle(
color: Colors.white70,
fontSize: 11,
fontWeight: FontWeight.w500,
),
),
],
);
}
}

// =======================================================
// ATTENDANCE CARD
// =======================================================

class _AttendanceCard extends StatelessWidget {
const _AttendanceCard({
required this.attendance,
required this.isTablet,
});

final Attendance attendance;
final bool isTablet;

@override
Widget build(BuildContext context) {
final isCheckIn =
attendance.type == 'check_in';

final dateTime =
_parseDate(attendance.occurredAt);

final hasPhoto =
attendance.photoPath != null &&
attendance.photoPath!
    .trim()
    .isNotEmpty;

final hasLocation =
attendance.latitude != null &&
attendance.longitude != null;

return Container(
margin: const EdgeInsets.only(
bottom: 16,
),

padding: EdgeInsets.all(
isTablet ? 20 : 16,
),

decoration: BoxDecoration(
color: Colors.white,

borderRadius:
BorderRadius.circular(20),

border: Border.all(
color: Colors.grey.withValues(
alpha: 0.12,
),
),

boxShadow: [
BoxShadow(
color: Colors.black.withValues(
alpha: 0.035,
),
blurRadius: 12,
offset: const Offset(0, 5),
),
],
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
// ============================================
// ATTENDANCE HEADER
// ============================================

Row(
children: [
Container(
width: 50,
height: 50,

decoration: BoxDecoration(
color: (isCheckIn
? Colors.green
    : Colors.orange)
    .withValues(
alpha: 0.10,
),

shape: BoxShape.circle,
),

child: Icon(
isCheckIn
? Icons.login_rounded
    : Icons.logout_rounded,

color: isCheckIn
? Colors.green.shade700
    : Colors.orange.shade700,

size: 25,
),
),

const SizedBox(width: 13),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Row(
children: [
Text(
isCheckIn
? 'Check In'
    : 'Check Out',

style: const TextStyle(
fontSize: 17,
fontWeight:
FontWeight.w800,
),
),

const SizedBox(width: 8),

Container(
padding:
const EdgeInsets
    .symmetric(
horizontal: 8,
vertical: 3,
),

decoration:
BoxDecoration(
color: (isCheckIn
? Colors.green
    : Colors.orange)
    .withValues(
alpha: 0.10,
),
borderRadius:
BorderRadius
    .circular(
20,
),
),

child: Text(
isCheckIn
? 'IN'
    : 'OUT',

style: TextStyle(
color: isCheckIn
? Colors.green
    .shade700
    : Colors.orange
    .shade700,
fontSize: 10,
fontWeight:
FontWeight.w800,
),
),
),
],
),

const SizedBox(height: 4),

Text(
_formatDate(dateTime),

style:
const TextStyle(
color: Colors.grey,
fontSize: 12,
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
_formatTime(dateTime),

style: TextStyle(
color:
AppColors.primary,
fontSize: 17,
fontWeight:
FontWeight.w900,
),
),

const SizedBox(height: 3),

const Text(
'Recorded time',
style: TextStyle(
color: Colors.grey,
fontSize: 9,
),
),
],
),
],
),

const SizedBox(height: 18),

// ============================================
// PHOTO
// ============================================

if (hasPhoto)
_buildPhotoSection(
context,
attendance,
),

if (hasPhoto && hasLocation)
const SizedBox(height: 18),

// ============================================
// LOCATION
// ============================================

if (hasLocation)
_buildLocationSection(
context,
attendance,
),

// ============================================
// DEVICE
// ============================================

if (attendance.deviceId != null &&
attendance.deviceId!
    .trim()
    .isNotEmpty) ...[
const SizedBox(height: 14),

_InfoRow(
icon: Icons.phone_android_rounded,
label: 'Device',
value:
attendance.deviceId!,
),
],

// ============================================
// REMARKS
// ============================================

if (attendance.remarks != null &&
attendance.remarks!
    .trim()
    .isNotEmpty) ...[
const SizedBox(height: 10),

_InfoRow(
icon: Icons.notes_rounded,
label: 'Remarks',
value:
attendance.remarks!,
),
],

// ============================================
// SYNC STATUS
// ============================================

if (attendance.syncStatus !=
null &&
attendance.syncStatus!
    .trim()
    .isNotEmpty) ...[
const SizedBox(height: 12),

Row(
children: [
Icon(
Icons.sync_rounded,
size: 16,
color:
_syncStatusColor(
attendance.syncStatus!,
),
),

const SizedBox(width: 7),

Text(
'Sync: '
'${attendance.syncStatus!}',

style: TextStyle(
color:
_syncStatusColor(
attendance.syncStatus!,
),
fontSize: 12,
fontWeight:
FontWeight.w600,
),
),
],
),
],
],
),
);
}

// =====================================================
// PHOTO SECTION
// =====================================================

Widget _buildPhotoSection(
BuildContext context,
Attendance attendance,
) {
final path =
attendance.photoPath!;

return Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
const Text(
'Attendance Photo',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 10),

GestureDetector(
onTap: () {
_showPhoto(
context,
path,
);
},

child: ClipRRect(
borderRadius:
BorderRadius.circular(16),

child: Stack(
children: [
Image.network(
_photoUrl(path),

width: double.infinity,
height: 230,

fit: BoxFit.cover,

loadingBuilder: (
context,
child,
loadingProgress,
) {
if (loadingProgress ==
null) {
return child;
}

return Container(
width:
double.infinity,
height: 230,
color:
Colors.grey.shade100,

child: const Center(
child:
CircularProgressIndicator(),
),
);
},

errorBuilder: (
context,
error,
stackTrace,
) {
return Container(
width:
double.infinity,
height: 230,
color:
Colors.grey.shade100,

child: Column(
mainAxisAlignment:
MainAxisAlignment
    .center,

children: [
Icon(
Icons
    .broken_image_outlined,
size: 48,
color:
Colors.grey
    .shade400,
),

const SizedBox(
height: 8,
),

const Text(
'Unable to load photo',
style: TextStyle(
color:
Colors.grey,
fontSize: 13,
),
),
],
),
);
},
),

// Zoom icon
Positioned(
right: 12,
bottom: 12,

child: Container(
width: 38,
height: 38,

decoration:
BoxDecoration(
color: Colors.black
    .withValues(
alpha: 0.55,
),
shape:
BoxShape.circle,
),

child: const Icon(
Icons.zoom_in,
color:
Colors.white,
size: 21,
),
),
),
],
),
),
),

const SizedBox(height: 7),

const Row(
children: [
Icon(
Icons.touch_app_outlined,
size: 15,
color: Colors.grey,
),

SizedBox(width: 5),

Text(
'Tap photo to view full size',
style: TextStyle(
color: Colors.grey,
fontSize: 11,
),
),
],
),
],
);
}

// =====================================================
// LOCATION SECTION
// =====================================================

Widget _buildLocationSection(
BuildContext context,
Attendance attendance,
) {
final latitude =
attendance.latitude!;

final longitude =
attendance.longitude!;

return Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
const Text(
'Location',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 10),

Material(
color: Colors.transparent,

child: InkWell(
borderRadius:
BorderRadius.circular(16),

onTap: () {
_openLocation(
context,
latitude,
longitude,
);
},

child: Container(
padding:
const EdgeInsets.all(14),

decoration: BoxDecoration(
color: AppColors.primary
    .withValues(
alpha: 0.055,
),

borderRadius:
BorderRadius.circular(16),

border: Border.all(
color: AppColors.primary
    .withValues(
alpha: 0.14,
),
),
),

child: Row(
children: [
Container(
width: 46,
height: 46,

decoration:
BoxDecoration(
color: AppColors
    .primary
    .withValues(
alpha: 0.11,
),
shape:
BoxShape.circle,
),

child: Icon(
Icons.location_on_rounded,
color:
AppColors.primary,
),
),

const SizedBox(width: 12),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,

children: [
const Text(
'GPS Coordinates',
style: TextStyle(
fontSize: 12,
color: Colors.grey,
),
),

const SizedBox(height: 4),

Text(
'${latitude.toStringAsFixed(7)}, '
'${longitude.toStringAsFixed(7)}',

style:
const TextStyle(
fontSize: 13,
fontWeight:
FontWeight.w700,
),
),

if (attendance
    .accuracy !=
null) ...[
const SizedBox(
height: 4,
),

Text(
'Accuracy: '
'${attendance.accuracy!.toStringAsFixed(2)} m',

style:
const TextStyle(
color: Colors.grey,
fontSize: 11,
),
),
],

const SizedBox(height: 5),

Text(
'Tap to open Google Maps',

style: TextStyle(
color:
AppColors.primary,
fontSize: 11,
fontWeight:
FontWeight.w700,
),
),
],
),
),

Icon(
Icons
    .open_in_new_rounded,
color:
AppColors.primary,
size: 20,
),
],
),
),
),
),
],
);
}

// =====================================================
// PHOTO URL
// =====================================================

String _photoUrl(
String? path,
) {
if (path == null ||
path.trim().isEmpty) {
return '';
}

final baseUrl =
ApiConfig.baseUrl
    .replaceFirst('/api', '');

String cleanPath =
path.trim();

if (cleanPath.startsWith('/')) {
cleanPath =
cleanPath.substring(1);
}

if (cleanPath.startsWith(
'storage/',
)) {
cleanPath =
cleanPath.substring(
'storage/'.length,
);
}

return '$baseUrl/storage/$cleanPath';
}

// =====================================================
// SHOW PHOTO
// =====================================================

void _showPhoto(
BuildContext context,
String path,
) {
showDialog(
context: context,

barrierColor:
Colors.black.withValues(
alpha: 0.90,
),

builder: (_) {
return Dialog(
backgroundColor:
Colors.transparent,

insetPadding:
const EdgeInsets.all(10),

child: Stack(
children: [
Center(
child: InteractiveViewer(
minScale: 0.8,
maxScale: 4.0,

child: ClipRRect(
borderRadius:
BorderRadius.circular(
12,
),

child: Image.network(
_photoUrl(path),

fit: BoxFit.contain,

errorBuilder: (
context,
error,
stackTrace,
) {
return Container(
width: 300,
height: 250,
color: Colors.black,
alignment:
Alignment.center,

child:
const Text(
'Unable to load photo',
style: TextStyle(
color:
Colors.white,
),
),
);
},
),
),
),
),

Positioned(
top: 5,
right: 5,

child: Container(
decoration:
const BoxDecoration(
color: Colors.black54,
shape:
BoxShape.circle,
),

child: IconButton(
onPressed: () {
Navigator.of(
context,
).pop();
},

icon: const Icon(
Icons.close,
color:
Colors.white,
),
),
),
),
],
),
);
},
);
}

// =====================================================
// OPEN LOCATION
// =====================================================

Future<void> _openLocation(
BuildContext context,
double latitude,
double longitude,
) async {
final uri = Uri.parse(
'https://www.google.com/maps/search/'
'?api=1&query=$latitude,$longitude',
);

try {
final launched =
await launchUrl(
uri,
mode:
LaunchMode.externalApplication,
);

if (!launched &&
context.mounted) {
ScaffoldMessenger.of(
context,
).showSnackBar(
const SnackBar(
content: Text(
'Unable to open Google Maps.',
),
),
);
}
} catch (_) {
if (!context.mounted) {
return;
}

ScaffoldMessenger.of(
context,
).showSnackBar(
const SnackBar(
content: Text(
'Unable to open location.',
),
),
);
}
}

// =====================================================
// DATE PARSER
// =====================================================

DateTime? _parseDate(
String? value,
) {
if (value == null ||
value.trim().isEmpty) {
return null;
}

final parsed =
DateTime.tryParse(value);

if (parsed == null) {
return null;
}

return parsed.toLocal();
}

// =====================================================
// FORMAT DATE
// =====================================================

String _formatDate(
DateTime? dateTime,
) {
if (dateTime == null) {
return '--';
}

final day =
dateTime.day
    .toString()
    .padLeft(2, '0');

final month =
dateTime.month
    .toString()
    .padLeft(2, '0');

final year =
dateTime.year.toString();

return '$day/$month/$year';
}

// =====================================================
// FORMAT TIME
// =====================================================

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '--:--';
    }

    final hour24 = dateTime.hour;

    final hour = hour24 == 0
        ? 12
        : hour24 > 12
        ? hour24 - 12
        : hour24;

    final minute = dateTime.minute
        .toString()
        .padLeft(2, '0');

    final period = hour24 >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

// =====================================================
// SYNC STATUS COLOR
// =====================================================

Color _syncStatusColor(
String status,
) {
switch (status.toLowerCase()) {
case 'synced':
return Colors.green;

case 'pending':
return Colors.orange;

case 'failed':
return Colors.red;

default:
return Colors.grey;
}
}
}

// =======================================================
// INFORMATION ROW
// =======================================================

class _InfoRow extends StatelessWidget {
const _InfoRow({
required this.icon,
required this.label,
required this.value,
});

final IconData icon;
final String label;
final String value;

@override
Widget build(BuildContext context) {
return Row(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Icon(
icon,
size: 17,
color: Colors.grey,
),

const SizedBox(width: 8),

Text(
'$label: ',
style: const TextStyle(
color: Colors.grey,
fontSize: 12,
fontWeight: FontWeight.w600,
),
),

Expanded(
child: Text(
value,

style: const TextStyle(
color: Colors.black87,
fontSize: 12,
),
),
),
],
);
}
}

