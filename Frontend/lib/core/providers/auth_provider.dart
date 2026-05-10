import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _user;
  String? _token;
  bool _isLoading = true;

  Usuario? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isManager => _user?.tipo == 'GERENTE' || _user?.tipo == 'ADMIN';

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    // TODO: Carregar usuário do storage ou buscar na API se tiver token
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: Implementar chamada ao AuthService
      // _token = ...
      // _user = ...
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString(AppConstants.tokenKey, _token!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    notifyListeners();
  }
}
