import 'package:flutter/material.dart';
import '../../../../core/models/cliente.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

class ClientsProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _error;

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchClients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/clientes');
      _clientes = (response.data as List).map((c) => Cliente.fromJson(c)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erro inesperado ao carregar clientes';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
