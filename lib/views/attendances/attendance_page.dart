import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../viewmodels/attendance_view_model.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceViewModel(),
      child: const _AttendanceContent(),
    );
  }
}

class _AttendanceContent extends StatefulWidget {
  const _AttendanceContent();

  @override
  State<_AttendanceContent> createState() =>
      _AttendanceContentState();
}

class _AttendanceContentState
    extends State<_AttendanceContent> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _remarksController =
  TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  File? _photo;

  Position? _position;

  bool _gettingLocation = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1200,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _photo = File(image.path);
    });
  }

  Future<void> _getLocation() async {
    setState(() {
      _gettingLocation = true;
    });

    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Please enable location/GPS on your phone.',
        );
      }

      var permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required for check in.',
        );
      }

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _position = position;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  Future<void> _checkIn() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_position == null) {
      await _getLocation();

      if (_position == null) {
        return;
      }
    }

    final viewModel =
    context.read<AttendanceViewModel>();

    final success = await viewModel.checkIn(
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      accuracy: _position!.accuracy,
      photo: _photo,
      remarks: _remarksController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ??
                'Failed to check in.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 60,
          ),
          title: const Text(
            'Check In Successful',
          ),
          content: const Text(
            'Your attendance has been recorded successfully.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('DONE'),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Consumer<AttendanceViewModel>(
          builder: (
              context,
              viewModel,
              child,
              ) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 24),

                    _buildLocationCard(),

                    const SizedBox(height: 16),

                    _buildPhotoCard(),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                      _remarksController,
                      maxLines: 3,
                      decoration:
                      InputDecoration(
                        labelText: 'Remarks',
                        hintText:
                        'Optional remarks',
                        prefixIcon: const Icon(
                          Icons.notes,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                        viewModel.isLoading
                            ? null
                            : _checkIn,
                        icon: viewModel.isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.login,
                        ),
                        label: Text(
                          viewModel.isLoading
                              ? 'CHECKING IN...'
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.access_time_filled,
            size: 52,
            color: AppColors.primary,
          ),
          SizedBox(height: 12),
          Text(
            'Employee Check In',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Record your attendance using your current location.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),
                SizedBox(width: 10),
                Text(
                  'Current Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_position == null)
              const Text(
                'Location has not been captured yet.',
              )
            else
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latitude: ${_position!.latitude}',
                  ),
                  Text(
                    'Longitude: ${_position!.longitude}',
                  ),
                  Text(
                    'Accuracy: ${_position!.accuracy.toStringAsFixed(2)} m',
                  ),
                ],
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _gettingLocation
                    ? null
                    : _getLocation,
                icon: _gettingLocation
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.my_location,
                ),
                label: Text(
                  _gettingLocation
                      ? 'Getting Location...'
                      : 'Get Current Location',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: AppColors.primary,
                ),
                SizedBox(width: 10),
                Text(
                  'Attendance Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_photo != null)
              ClipRRect(
                borderRadius:
                BorderRadius.circular(12),
                child: Image.file(
                  _photo!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 45,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No photo captured',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(
                  Icons.camera_alt,
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
}