import 'package:flutter/material.dart';
import '../services/ibooking_service.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/models/plano_seguro.dart';

class BookingProvider extends ChangeNotifier {
  final IBookingService _service;

  BookingProvider(this._service);

  Veiculo? _selectedVehicle;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _pickupBranchId;
  String? _returnBranchId;
  PlanoSeguro? _selectedInsurance;
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _availabilityResult;
  String? _currentReservaId;
  String? _paymentStatus;

  // Getters
  Veiculo? get selectedVehicle => _selectedVehicle;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  PlanoSeguro? get selectedInsurance => _selectedInsurance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get availabilityResult => _availabilityResult;
  String? get paymentStatus => _paymentStatus;

  void selectVehicle(Veiculo vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void setDates(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setBranches(String pickup, String returns) {
    _pickupBranchId = pickup;
    _returnBranchId = returns;
    notifyListeners();
  }

  void selectInsurance(PlanoSeguro insurance) {
    _selectedInsurance = insurance;
    notifyListeners();
  }

  Future<void> checkAvailability() async {
    if (_selectedVehicle == null || _startDate == null || _endDate == null || _pickupBranchId == null) {
      _error = 'Dados incompletos para verificar disponibilidade';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availabilityResult = await _service.verificarDisponibilidade(
        modeloId: _selectedVehicle!.modeloId!,
        filialId: _pickupBranchId!,
        dataInicio: _startDate!,
        dataFim: _endDate!,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> initiatePayment(String clienteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.iniciarPagamento(
        modeloId: _selectedVehicle!.modeloId!,
        filialRetiradaId: _pickupBranchId!,
        filialDevolucaoId: _returnBranchId ?? _pickupBranchId!,
        dataInicio: _startDate!,
        dataFim: _endDate!,
        clienteId: clienteId,
        planoSeguroId: _selectedInsurance?.id ?? 'BASICO',
      );
      _currentReservaId = result['id'];
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pollPaymentStatus() async {
    if (_currentReservaId == null) return;

    try {
      final result = await _service.consultarStatusPagamento(_currentReservaId!);
      _paymentStatus = result['status'];
      notifyListeners();
    } catch (e) {
      // Falha silenciosa no polling ou logar
    }
  }
}
