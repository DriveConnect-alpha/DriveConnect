import '../providers/dashboard_provider.dart';

abstract class IDashboardService {
  Future<DashboardStats> getStats();
}
