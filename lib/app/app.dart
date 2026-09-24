import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../views/auth/login_page.dart';

class StaffAttendanceApp extends StatelessWidget {
  const StaffAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Staff Attendance Management System',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor:
        AppColors.background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),

        inputDecorationTheme:
        const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(12),
            ),
          ),
        ),
      ),

      home: const LoginPage(),
    );
  }
}