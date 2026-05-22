import 'package:flutter/material.dart';
import '../../../../core/models/cliente.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

import '../services/iclient_manager_service.dart';

class ClientsProvider with ChangeNotifier {
  final IClientManagerService _service;
  
  ClientsProvider(this._service);
  
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
      _clientes = await _service.getClients();
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
