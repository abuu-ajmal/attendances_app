import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AttendanceFileService {
  AttendanceFileService._();

  static final AttendanceFileService instance =
  AttendanceFileService._();

  Future<String?> saveAttendancePhoto(
      File? source,
      String uuid,
      ) async {
    if (source == null) {
      return null;
    }

    if (!await source.exists()) {
      return null;
    }

    final directory =
    await getApplicationDocumentsDirectory();

    final attendanceDirectory = Directory(
      path.join(
        directory.path,
        'attendance_photos',
      ),
    );

    if (!await attendanceDirectory.exists()) {
      await attendanceDirectory.create(
        recursive: true,
      );
    }

    final extension =
    path.extension(source.path).isEmpty
        ? '.jpg'
        : path.extension(source.path);

    final destination = File(
      path.join(
        attendanceDirectory.path,
        '$uuid$extension',
      ),
    );

    await source.copy(destination.path);

    return destination.path;
  }
}