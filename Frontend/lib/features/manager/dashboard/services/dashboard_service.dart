import '../../../../core/network/api_client.dart';
import '../providers/dashboard_provider.dart';
import 'idashboard_service.dart';

class DashboardService implements IDashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  @override
  Future<DashboardStats> getStats() async {
    final response = await _apiClient.get('/dashboard/stats');
    return DashboardStats.fromJson(response.data);
  }
}
