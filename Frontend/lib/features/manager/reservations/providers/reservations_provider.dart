import 'package:flutter/material.dart';
import '../../../../core/models/reserva.dart';
import '../../../../core/network/api_exceptions.dart';

import '../services/ireservation_manager_service.dart';

class ReservationsProvider with ChangeNotifier {
  final IReservationManagerService _service;
  
  ReservationsProvider(this._service);
  
  List<Reserva> _reservas = [];
  bool _isLoading = false;
  String? _error;

  List<Reserva> get reservas => _reservas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReservations({String? clienteId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reservas = await _service.getManagerReservations(clienteId: clienteId);
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
      await _service.updateReservationStatus(id, status);
      await fetchReservations();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> createReservation({
    required String veiculoId,
    required String clienteId,
    required String filialRetiradaId,
    required String filialDevolucaoId,
    required String dataInicio,
    required String dataFim,
    String? planoSeguroId,
    String? metodoPagamento,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.createReservation(
        veiculoId: veiculoId,
        clienteId: clienteId,
        filialRetiradaId: filialRetiradaId,
        filialDevolucaoId: filialDevolucaoId,
        dataInicio: dataInicio,
        dataFim: dataFim,
        planoSeguroId: planoSeguroId,
        metodoPagamento: metodoPagamento,
      );
      await fetchReservations();
      return result;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = 'Erro inesperado ao criar reserva';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
