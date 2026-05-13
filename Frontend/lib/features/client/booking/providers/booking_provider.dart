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
  String _paymentMethod = 'INFINITEPAY'; // 'INFINITEPAY' ou 'DINHEIRO'
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _availabilityResult;
  String? _currentReservaId;
  String? _paymentStatus;
  List<DateTimeRange> _occupiedDates = [];

  // Getters
  Veiculo? get selectedVehicle => _selectedVehicle;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  PlanoSeguro? get selectedInsurance => _selectedInsurance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get availabilityResult => _availabilityResult;
  String? get paymentStatus => _paymentStatus;
  String get paymentMethod => _paymentMethod;
  List<DateTimeRange> get occupiedDates => _occupiedDates;

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void selectVehicle(Veiculo vehicle) {
    _selectedVehicle = vehicle;
    _occupiedDates = []; // Limpa anteriores
    if (vehicle.id != null) {
      loadOccupiedDates(vehicle.id!);
    }
    notifyListeners();
  }

  Future<void> loadOccupiedDates(String veiculoId) async {
    try {
      final data = await _service.getOccupiedDates(veiculoId);
      _occupiedDates = data.map((item) {
        return DateTimeRange(
          start: DateTime.parse(item['data_inicio']),
          end: DateTime.parse(item['data_fim']),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar datas ocupadas: $e');
    }
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
        metodoPagamento: _paymentMethod,
      );
      _currentReservaId = result['id'] ?? result['reserva_id'];
      _paymentStatus = result['status']; // Se for DINHEIRO, virá 'RESERVADA'
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
