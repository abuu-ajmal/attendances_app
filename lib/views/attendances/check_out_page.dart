
import 'dart:io';
import '../../services/device_service.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../viewmodels/check_out_view_model.dart';



class CheckOutPage extends StatelessWidget {
const CheckOutPage({super.key});

@override
Widget build(BuildContext context) {
return ChangeNotifierProvider(
create: (_) => CheckOutViewModel(),
child: const _CheckOutPageContent(),
);
}
}

class _CheckOutPageContent extends StatefulWidget {
const _CheckOutPageContent();

@override
State<_CheckOutPageContent> createState() =>
_CheckOutPageContentState();
}

class _CheckOutPageContentState
extends State<_CheckOutPageContent> {
final ImagePicker _picker = ImagePicker();

final TextEditingController _remarksController =
TextEditingController();

File? _photo;

Position? _position;

bool _gettingLocation = false;
bool _gettingPhoto = false;

@override
void dispose() {
_remarksController.dispose();
super.dispose();
}

// ============================================================
// GET LOCATION
// ============================================================

Future<void> _getLocation() async {
setState(() {
_gettingLocation = true;
});

try {
final serviceEnabled =
await Geolocator.isLocationServiceEnabled();

if (!serviceEnabled) {
throw Exception(
'Location service is disabled. Please enable GPS.',
);
}

LocationPermission permission =
await Geolocator.checkPermission();

if (permission == LocationPermission.denied) {
permission =
await Geolocator.requestPermission();
}

if (permission == LocationPermission.denied) {
throw Exception(
'Location permission was denied.',
);
}

if (permission ==
LocationPermission.deniedForever) {
throw Exception(
'Location permission is permanently denied. '
'Please enable it from Settings.',
);
}

final position =
await Geolocator.getCurrentPosition(
locationSettings: const LocationSettings(
accuracy: LocationAccuracy.high,
),
);

if (!mounted) return;

setState(() {
_position = position;
});
} catch (e) {
if (!mounted) return;

_showMessage(
e.toString().replaceFirst(
'Exception: ',
'',
),
isError: true,
);
} finally {
if (mounted) {
setState(() {
_gettingLocation = false;
});
}
}
}

// ============================================================
// TAKE PHOTO
// ============================================================

Future<void> _takePhoto() async {
setState(() {
_gettingPhoto = true;
});

try {
final XFile? image =
await _picker.pickImage(
source: ImageSource.camera,
imageQuality: 80,
);

if (image != null && mounted) {
setState(() {
_photo = File(image.path);
});
}
} catch (_) {
if (mounted) {
_showMessage(
'Unable to capture photo.',
isError: true,
);
}
} finally {
if (mounted) {
setState(() {
_gettingPhoto = false;
});
}
}
}

// ============================================================
// SUBMIT CHECK OUT
// ============================================================

  Future<void> _submit() async {
    if (_photo == null) {
      _showMessage(
        'Please take your checkout photo.',
        isError: true,
      );

      return;
    }

    if (_position == null) {
      _showMessage(
        'Please capture your current location.',
        isError: true,
      );

      return;
    }

    final String uuid =
    const Uuid().v4();

    final deviceId =
    await DeviceService.instance
        .getDeviceName();

    final DateTime now =
    DateTime.now();

    final viewModel =
    context.read<CheckOutViewModel>();

    final success =
    await viewModel.submitCheckOut(
      occurredAt: now,
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      accuracy: _position!.accuracy,
      deviceId: deviceId,
      uuid: uuid,
      photo: _photo,
      remarks:
      _remarksController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        viewModel.errorMessage ??
            'Failed to check out.',
        isError: true,
      );

      return;
    }

    final isPending =
        viewModel.attendance?.syncStatus ==
            'pending';

    if (isPending) {
      _showMessage(
        'Check out saved offline. It will be synchronized automatically when internet is available.',
      );
    }

    _showSuccessDialog(
      offline: isPending,
    );
  }

// ============================================================
// MESSAGE
// ============================================================

void _showMessage(
String message, {
bool isError = false,
}) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor:
isError
? Colors.red
    : Colors.green,
),
);
}

// ============================================================
// SUCCESS
// ============================================================

  void _showSuccessDialog({
    bool offline = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),
          icon: Icon(
            offline
                ? Icons.cloud_off
                : Icons.check_circle,
            color: offline
                ? Colors.orange
                : Colors.green,
            size: 64,
          ),
          title: Text(
            offline
                ? 'Saved Offline'
                : 'Check Out Successful',
            textAlign: TextAlign.center,
          ),
          content: Text(
            offline
                ? 'Your check out has been saved on this device. It will be synchronized automatically when internet connection is available.'
                : 'Your check out has been recorded successfully.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();

                  Navigator.of(
                    context,
                  ).pop();
                },
                child: const Text(
                  'Done',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// ============================================================
// BUILD
// ============================================================

@override
Widget build(BuildContext context) {
return Consumer<CheckOutViewModel>(
builder: (
context,
viewModel,
child,
) {
return Scaffold(
appBar: AppBar(
title: const Text(
'Check Out',
),
centerTitle: true,
),
body: SafeArea(
child: SingleChildScrollView(
padding:
const EdgeInsets.all(20),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.stretch,
children: [
_header(),

const SizedBox(
height: 24,
),

_photoCard(),

const SizedBox(
height: 20,
),

_locationCard(),

const SizedBox(
height: 20,
),

_remarksField(),

const SizedBox(
height: 28,
),

_checkoutButton(
viewModel,
),

if (viewModel.errorMessage !=
null) ...[
const SizedBox(
height: 16,
),
_errorMessage(
viewModel.errorMessage!,
),
],
],
),
),
),
);
},
);
}

// ============================================================
// HEADER
// ============================================================

Widget _header() {
return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
borderRadius:
BorderRadius.circular(20),
color:
Colors.orange.withOpacity(.08),
),
child: const Column(
children: [
Icon(
Icons.logout,
size: 48,
color: Colors.orange,
),

SizedBox(
height: 10,
),

Text(
'End Your Working Day',
style: TextStyle(
fontSize: 22,
fontWeight:
FontWeight.bold,
),
textAlign:
TextAlign.center,
),

SizedBox(
height: 6,
),

Text(
'Take a photo and capture your current location before checking out.',
textAlign:
TextAlign.center,
),
],
),
);
}

// ============================================================
// PHOTO CARD
// ============================================================

Widget _photoCard() {
return Card(
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(18),
side: BorderSide(
color:
Colors.grey.shade300,
),
),
child: Padding(
padding:
const EdgeInsets.all(16),
child: Column(
children: [
const Align(
alignment:
Alignment.centerLeft,
child: Text(
'Checkout Photo',
style: TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
),

const SizedBox(
height: 14,
),

if (_photo != null)
ClipRRect(
borderRadius:
BorderRadius.circular(
16,
),
child: Image.file(
_photo!,
height: 230,
width:
double.infinity,
fit: BoxFit.cover,
),
)
else
Container(
height: 180,
width:
double.infinity,
decoration:
BoxDecoration(
borderRadius:
BorderRadius.circular(
16,
),
color:
Colors.grey.shade100,
),
child: const Column(
mainAxisAlignment:
MainAxisAlignment
    .center,
children: [
Icon(
Icons
    .camera_alt_outlined,
size: 50,
color:
Colors.grey,
),

SizedBox(
height: 8,
),

Text(
'No photo captured',
),
],
),
),

const SizedBox(
height: 14,
),

SizedBox(
width:
double.infinity,
child:
OutlinedButton.icon(
onPressed:
_gettingPhoto
? null
    : _takePhoto,
icon: _gettingPhoto
? const SizedBox(
height: 18,
width: 18,
child:
CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Icon(
Icons
    .camera_alt,
),
label: Text(
_photo == null
? 'Take Photo'
    : 'Retake Photo',
),
),
),
],
),
),
);
}

// ============================================================
// LOCATION CARD
// ============================================================

Widget _locationCard() {
return Card(
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(18),
side: BorderSide(
color:
Colors.grey.shade300,
),
),
child: Padding(
padding:
const EdgeInsets.all(16),
child: Column(
children: [
const Align(
alignment:
Alignment.centerLeft,
child: Text(
'Current Location',
style: TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
),

const SizedBox(
height: 14,
),

if (_position == null)
Container(
width:
double.infinity,
padding:
const EdgeInsets.all(
18,
),
decoration:
BoxDecoration(
color:
Colors.grey.shade100,
borderRadius:
BorderRadius.circular(
14,
),
),
child: const Row(
children: [
Icon(
Icons
    .location_off,
color:
Colors.grey,
),

SizedBox(
width: 12,
),

Expanded(
child: Text(
'Location not captured',
),
),
],
),
)
else
Container(
width:
double.infinity,
padding:
const EdgeInsets.all(
18,
),
decoration:
BoxDecoration(
color: Colors.green
    .withOpacity(.08),
borderRadius:
BorderRadius.circular(
14,
),
),
child: Column(
children: [
const Icon(
Icons.location_on,
color:
Colors.green,
size: 35,
),

const SizedBox(
height: 10,
),

Text(
'Latitude: '
'${_position!.latitude.toStringAsFixed(6)}',
),

Text(
'Longitude: '
'${_position!.longitude.toStringAsFixed(6)}',
),

Text(
'Accuracy: '
'${_position!.accuracy.toStringAsFixed(2)} m',
),
],
),
),

const SizedBox(
height: 14,
),

SizedBox(
width:
double.infinity,
child:
OutlinedButton.icon(
onPressed:
_gettingLocation
? null
    : _getLocation,
icon: _gettingLocation
? const SizedBox(
height: 18,
width: 18,
child:
CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Icon(
Icons
    .my_location,
),
label: Text(
_position == null
? 'Get Current Location'
    : 'Refresh Location',
),
),
),
],
),
),
);
}

// ============================================================
// REMARKS
// ============================================================

Widget _remarksField() {
return TextField(
controller:
_remarksController,
maxLines: 3,
maxLength: 1000,
decoration:
InputDecoration(
labelText: 'Remarks',
hintText:
'Enter remarks (optional)',
prefixIcon:
const Icon(
Icons.notes_outlined,
),
border:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
16,
),
),
),
);
}

// ============================================================
// CHECK OUT BUTTON
// ============================================================

Widget _checkoutButton(
CheckOutViewModel viewModel,
) {
return SizedBox(
height: 55,
child: ElevatedButton.icon(
onPressed:
viewModel.isLoading
? null
    : _submit,
icon: viewModel.isLoading
? const SizedBox(
height: 22,
width: 22,
child:
CircularProgressIndicator(
strokeWidth: 2,
color:
Colors.white,
),
)
    : const Icon(
Icons.logout,
),
label: Text(
viewModel.isLoading
? 'Checking Out...'
    : 'CHECK OUT',
style:
const TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
),
style:
ElevatedButton.styleFrom(
backgroundColor:
Colors.orange,
foregroundColor:
Colors.white,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
16,
),
),
),
),
);
}

// ============================================================
// ERROR MESSAGE
// ============================================================

Widget _errorMessage(
String message,
) {
return Container(
padding:
const EdgeInsets.all(14),
decoration: BoxDecoration(
color:
Colors.red.withOpacity(.08),
borderRadius:
BorderRadius.circular(12),
),
child: Row(
children: [
const Icon(
Icons.error_outline,
color: Colors.red,
),

const SizedBox(
width: 10,
),

Expanded(
child: Text(
message,
style:
const TextStyle(
color: Colors.red,
),
),
),
],
),
);
}
}
