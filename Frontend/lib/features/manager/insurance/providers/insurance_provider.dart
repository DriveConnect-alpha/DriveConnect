import 'package:flutter/material.dart';
import '../../../../core/models/plano_seguro.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

class InsuranceProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<PlanoSeguro> _planos = [];
  bool _isLoading = false;
  String? _error;

  List<PlanoSeguro> get planos => _planos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPlanos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/planos-seguro');
      _planos = (response.data as List).map((p) => PlanoSeguro.fromJson(p)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erro inesperado ao carregar planos de seguro';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePlano(String id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('/planos-seguro/$id', data: data);
      await fetchPlanos();
      return true;
    } catch (e) {
      return false;
    }
  }
}
