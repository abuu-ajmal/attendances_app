
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../viewmodels/notification_view_model.dart';

class WarningLetterPage extends StatefulWidget {
const WarningLetterPage({
super.key,
});

@override
State<WarningLetterPage> createState() =>
_WarningLetterPageState();
}

class _WarningLetterPageState
extends State<WarningLetterPage> {
PdfControllerPinch? _pdfController;

Uint8List? _pdfBytes;

bool _isLoading = true;
bool _isPrinting = false;

String? _errorMessage;

@override
void initState() {
super.initState();

WidgetsBinding.instance.addPostFrameCallback((_) {
_loadPdf();
});
}

// ============================================================
// LOAD PDF
// ============================================================

Future<void> _loadPdf() async {
try {
if (mounted) {
setState(() {
_isLoading = true;
_errorMessage = null;
});
}

final viewModel =
context.read<NotificationViewModel>();

final bytes =
await viewModel.downloadWarningLetter();

if (!mounted) {
return;
}

if (bytes.isEmpty) {
throw Exception(
'Warning letter is empty.',
);
}

final pdfBytes =
Uint8List.fromList(bytes);

final document =
await PdfDocument.openData(
pdfBytes,
);

if (!mounted) {
await document.close();
return;
}

setState(() {
_pdfBytes = pdfBytes;

_pdfController =
PdfControllerPinch(
document: Future.value(document),
);

_isLoading = false;
_errorMessage = null;
});
} catch (e) {
if (!mounted) {
return;
}

setState(() {
_isLoading = false;

_errorMessage =
e.toString().replaceFirst(
'Exception: ',
'',
);
});
}
}

// ============================================================
// PRINT PDF
// ============================================================

Future<void> _printPdf() async {
if (_pdfBytes == null ||
_pdfBytes!.isEmpty) {
ScaffoldMessenger.of(context)
    .showSnackBar(
const SnackBar(
content: Text(
'Warning letter is not ready for printing.',
),
),
);

return;
}

if (_isPrinting) {
return;
}

setState(() {
_isPrinting = true;
});

try {
await Printing.layoutPdf(
onLayout: (format) async {
return _pdfBytes!;
},
name: 'Attendance Warning Letter',
);
} catch (e) {
if (!mounted) {
return;
}

ScaffoldMessenger.of(context)
    .showSnackBar(
SnackBar(
content: Text(
'Unable to print warning letter: $e',
),
),
);
} finally {
if (!mounted) {
return;
}

setState(() {
_isPrinting = false;
});
}
}

// ============================================================
// DISPOSE
// ============================================================

@override
void dispose() {
_pdfController?.dispose();
super.dispose();
}

// ============================================================
// BUILD
// ============================================================

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor:
const Color(0xffF1F3F5),

appBar: AppBar(
backgroundColor:
AppColors.primary,

foregroundColor:
Colors.white,

elevation: 0,

title: const Text(
'Official Warning Letter',
style: TextStyle(
fontWeight: FontWeight.w700,
),
),

actions: [
if (!_isLoading &&
_pdfBytes != null &&
_pdfBytes!.isNotEmpty)
IconButton(
tooltip: 'Print Warning Letter',
onPressed:
_isPrinting
? null
    : _printPdf,
icon: _isPrinting
? const SizedBox(
width: 21,
height: 21,
child:
CircularProgressIndicator(
strokeWidth: 2,
valueColor:
AlwaysStoppedAnimation<
Color>(
Colors.white,
),
),
)
    : const Icon(
Icons.print_outlined,
size: 23,
),
),

const SizedBox(width: 6),
],
),

body: _buildBody(),
);
}

// ============================================================
// BODY
// ============================================================

Widget _buildBody() {
if (_isLoading) {
return const Center(
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
CircularProgressIndicator(),

SizedBox(height: 15),

Text(
'Loading official warning letter...',
style: TextStyle(
fontSize: 13,
fontWeight:
FontWeight.w500,
),
),
],
),
);
}

if (_errorMessage != null) {
return _buildError();
}

if (_pdfController == null) {
return _buildError(
message:
'Unable to display the warning letter.',
);
}

return PdfViewPinch(
controller:
_pdfController!,

scrollDirection:
Axis.vertical,
);
}

// ============================================================
// ERROR
// ============================================================

Widget _buildError({
String? message,
}) {
final error =
message ??
_errorMessage ??
'Unable to load warning letter.';

return Center(
child: Padding(
padding:
const EdgeInsets.all(30),

child: Column(
mainAxisAlignment:
MainAxisAlignment.center,

children: [
Container(
width: 75,
height: 75,

decoration:
BoxDecoration(
color:
Colors.red.withValues(
alpha: .08,
),

shape:
BoxShape.circle,
),

child: const Icon(
Icons
    .picture_as_pdf_outlined,

color: Colors.red,

size: 38,
),
),

const SizedBox(
height: 18,
),

const Text(
'Unable to open warning letter',

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
error,

textAlign:
TextAlign.center,

style: TextStyle(
color:
Colors.grey.shade600,

fontSize: 12,

height: 1.5,
),
),

const SizedBox(
height: 22,
),

ElevatedButton.icon(
onPressed: () {
_loadPdf();
},

icon: const Icon(
Icons.refresh,
),

label: const Text(
'Try Again',
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
horizontal: 20,
vertical: 12,
),

shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
10,
),
),
),
),
],
),
),
);
}
}

