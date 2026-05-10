import 'package:flutter/material.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

class InventoryProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Veiculo> _veiculos = [];
  bool _isLoading = false;
  String? _error;

  List<Veiculo> get veiculos => _veiculos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/veiculos');
      _veiculos = (response.data as List).map((v) => Veiculo.fromJson(v)).toList();
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
      await _apiClient.patch('/veiculos/$id/status', data: {'status': status});
      final index = _veiculos.indexWhere((v) => v.id == id);
      if (index != -1) {
        // Como o modelo é imutável em boas práticas, recriamos se necessário, 
        // ou apenas atualizamos a lista após o fetch.
        await fetchInventory(); 
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
