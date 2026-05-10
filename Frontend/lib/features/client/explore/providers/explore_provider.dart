import 'package:flutter/material.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';

class ExploreProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  List<Veiculo> _veiculos = [];
  bool _loading = false;
  String? _error;

  ExploreProvider(this._apiClient);

  List<Veiculo> get veiculos => _veiculos;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchVeiculos() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get('/veiculos');
      _veiculos = (response.data as List)
          .map((item) => Veiculo.fromJson(item))
          .toList();
    } catch (e) {
      _error = ApiErrorHandler.handle(e).message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
