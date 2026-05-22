import '../models/dashboard_stats.dart';

abstract class IDashboardService {
  Future<DashboardStats> getStats();
}
