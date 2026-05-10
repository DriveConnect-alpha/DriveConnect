import 'package:flutter/material.dart';
import '../../../../core/models/reserva.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

class ReservationsProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Reserva> _reservas = [];
  bool _isLoading = false;
  String? _error;

  List<Reserva> get reservas => _reservas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReservations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/reservas/gerente');
      _reservas = (response.data as List).map((r) => Reserva.fromJson(r)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erro inesperado ao carregar reservas';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _apiClient.patch('/reservas/$id/status', data: {'status': status});
      await fetchReservations();
      return true;
    } catch (e) {
      return false;
    }
  }
}
