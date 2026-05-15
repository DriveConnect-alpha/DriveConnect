import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

import '../services/iinventory_service.dart';

class InventoryProvider with ChangeNotifier {
  final IInventoryService _service;
  
  InventoryProvider(this._service);
  
  List<Veiculo> _veiculos = [];
  bool _isLoading = false;
  String? _error;

  List<Veiculo> get veiculos => _veiculos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _veiculos = await _service.getInventory();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erro inesperado ao carregar inventário';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVehicleStatus(String id, String status) async {
    try {
      await _service.updateVehicleStatus(id, status);
      await fetchInventory();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateVehicle(String id, {int? modeloId, String? filialId, String? placa, int? ano, String? cor, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateVehicle(id, modeloId: modeloId, filialId: filialId, placa: placa, ano: ano, cor: cor, status: status);
      await fetchInventory();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVehicle(Veiculo veiculo, {XFile? image, double? precoDiaria, List<String>? itensIds}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.addVehicle(veiculo, image: image, precoDiaria: precoDiaria, itensIds: itensIds);
      await fetchInventory();
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
