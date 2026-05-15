class DashboardStats {
  final int activeReservations;
  final int availableVehicles;
  final double monthlyRevenue;
  final int newClients;
  final List<RevenueData> revenueHistory;

  DashboardStats({
    required this.activeReservations,
    required this.availableVehicles,
    required this.monthlyRevenue,
    required this.newClients,
    this.revenueHistory = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeReservations: json['active_reservations'] ?? 0,
      availableVehicles: json['available_vehicles'] ?? 0,
      monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
      newClients: json['new_clients'] ?? 0,
      revenueHistory: (json['revenue_history'] as List? ?? [])
          .map((item) => RevenueData.fromJson(item))
          .toList(),
    );
  }
}

class RevenueData {
  final String month;
  final double amount;

  RevenueData({required this.month, required this.amount});

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      month: json['month'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}
