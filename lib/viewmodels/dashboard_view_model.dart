import 'package:flutter/foundation.dart';

import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    DashboardRepository? dashboardRepository,
  }) : _dashboardRepository =
      dashboardRepository ??
          DashboardRepository();

  final DashboardRepository _dashboardRepository;

  DashboardModel? _dashboard;

  DashboardModel? get dashboard => _dashboard;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final result =
      await _dashboardRepository
          .getDashboard();

      _dashboard = result;
    } catch (e) {
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

  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}