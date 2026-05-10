import 'package:flutter/material.dart';
import '../../../../core/models/reserva.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

class MyReservationsProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Reserva> _reservas = [];
  bool _isLoading = false;
  String? _error;

  List<Reserva> get reservas => _reservas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyReservations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/reservas/minhas');
      _reservas = (response.data as List).map((r) => Reserva.fromJson(r)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erro inesperado ao carregar suas reservas';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
