import 'package:flutter/material.dart';
import '../../../../core/models/reserva.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../booking/services/ibooking_service.dart';

class MyReservationsProvider with ChangeNotifier {
  final IBookingService _bookingService;
  
  MyReservationsProvider(this._bookingService);
  
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
      _reservas = await _bookingService.getMyReservations();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erro inesperado ao carregar suas reservas';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelarReserva(String reservaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _bookingService.cancelarReserva(reservaId);
      await fetchMyReservations();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
