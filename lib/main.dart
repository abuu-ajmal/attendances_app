import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/attendance_sync_service.dart';
import 'package:staff_attendances/viewmodels/notification_view_model.dart';

import 'app/app.dart';
import 'viewmodels/auth_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AttendanceSyncService.instance.start();


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationViewModel(),
        ),

      ],
      child: const StaffAttendanceApp(),
    ),
  );
}