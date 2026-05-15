import 'package:flutter/material.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

import '../services/iexplore_service.dart';

class ExploreProvider extends ChangeNotifier {
  final IExploreService _service;
  List<Veiculo> _veiculos = [];
  bool _loading = false;
  String? _error;

  ExploreProvider(this._service);

  List<Veiculo> get veiculos {
    if (_searchQuery.isEmpty && _selectedCategory == 'Todos') {
      return _veiculos;
    }
    return _veiculos.where((v) {
      final matchesSearch = (v.modelo?.nome?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? true) ||
                           (v.modelo?.marca?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? true);
      final matchesCategory = _selectedCategory == 'Todos' || v.modelo?.tipoCarro?.nome == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchVeiculos() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _veiculos = await _service.getAvailableVehicles();
    } catch (e) {
      _error = ApiErrorHandler.handle(e).message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
