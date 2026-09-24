import '../config/api_config.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';

class DashboardRepository {
  DashboardRepository({
    ApiService? apiService,
  }) : _apiService =
      apiService ?? ApiService.instance;

  final ApiService _apiService;

  Future<DashboardModel> getDashboard() async {
    final response = await _apiService.get(
      ApiConfig.dashboard,
      authenticated: true,
    );

    if (response['success'] != true) {
      throw Exception(
        'Failed to load dashboard data.',
      );
    }

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Invalid dashboard response.',
      );
    }

    return DashboardModel.fromJson(data);
  }
}