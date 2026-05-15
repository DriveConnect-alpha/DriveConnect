import 'package:flutter/material.dart';
import '../../../../core/models/plano_seguro.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

import '../services/iinsurance_service.dart';

class InsuranceProvider with ChangeNotifier {
  final IInsuranceService _service;
  
  InsuranceProvider(this._service);
  
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
      _planos = await _service.getPlanos();
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
      await _service.updatePlano(id, data);
      await fetchPlanos();
      return true;
    } catch (e) {
      return false;
    }
  }
}
