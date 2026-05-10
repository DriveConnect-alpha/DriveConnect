import '../models/dashboard_stats.dart';
import 'idashboard_service.dart';

class MockDashboardService implements IDashboardService {
  @override
  Future<DashboardStats> getStats() async {
    await Future.delayed(const Duration(seconds: 1));
    return DashboardStats(
      activeReservations: 12,
      availableVehicles: 45,
      monthlyRevenue: 25400.0,
      newClients: 8,
      revenueHistory: [
        RevenueData(month: 'Jan', amount: 18000),
        RevenueData(month: 'Fev', amount: 22000),
        RevenueData(month: 'Mar', amount: 25400),
      ],
    );
  }
}
