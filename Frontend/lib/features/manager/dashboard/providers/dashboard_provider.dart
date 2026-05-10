import 'package:flutter/material.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/dashboard_stats.dart';
import '../services/idashboard_service.dart';

class DashboardProvider with ChangeNotifier {
  final IDashboardService _service;
  
  DashboardProvider(this._service);
  
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
      _stats = await _service.getStats();
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
