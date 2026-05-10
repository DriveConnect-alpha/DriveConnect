import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

class DashboardStats {
  final int activeReservations;
  final int availableVehicles;
  final double monthlyRevenue;
  final int newClients;

  DashboardStats({
    required this.activeReservations,
    required this.availableVehicles,
    required this.monthlyRevenue,
    required this.newClients,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeReservations: json['active_reservations'] ?? 0,
      availableVehicles: json['available_vehicles'] ?? 0,
      monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
      newClients: json['new_clients'] ?? 0,
    );
  }
}

class DashboardProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  DashboardStats? _stats;
  bool _isLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/dashboard/stats');
      _stats = DashboardStats.fromJson(response.data);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erro ao carregar estatísticas do dashboard';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
