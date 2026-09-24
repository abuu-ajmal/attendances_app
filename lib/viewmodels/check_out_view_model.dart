
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../repositories/attendance_repository.dart';

class CheckOutViewModel extends ChangeNotifier {
CheckOutViewModel({
AttendanceRepository? repository,
}) : _repository =
repository ?? AttendanceRepository();

final AttendanceRepository _repository;

bool _isLoading = false;
String? _errorMessage;
String? _successMessage;

bool get isLoading => _isLoading;

String? get errorMessage => _errorMessage;

String? get successMessage => _successMessage;

void clearMessages() {
_errorMessage = null;
_successMessage = null;

notifyListeners();
}

Future<bool> submitCheckOut({
required DateTime occurredAt,
required double latitude,
required double longitude,
required double accuracy,
required String deviceId,
required String uuid,
File? photo,
String? remarks,
}) async {
_isLoading = true;
_errorMessage = null;
_successMessage = null;

notifyListeners();

try {
await _repository.checkOut(
uuid: uuid,
occurredAt: occurredAt.toIso8601String(),
latitude: latitude,
longitude: longitude,
accuracy: accuracy,
photo: photo,
deviceId: deviceId,
remarks: remarks,
);

_successMessage =
'Check out recorded successfully.';

return true;
} catch (e) {
_errorMessage = e
    .toString()
    .replaceFirst(
'Exception: ',
'',
);

return false;
} finally {
_isLoading = false;

notifyListeners();
}
}
}

