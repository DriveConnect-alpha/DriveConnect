import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../constants/app_constants.dart';
import '../../features/auth/services/iauth_service.dart';

class AuthProvider extends ChangeNotifier {
  final IAuthService _authService;
  Usuario? _user;
  String? _token;
  bool _isLoading = true;
  String? _error;

  Usuario? get user => _user;
  Usuario? get currentUser => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;
  bool get isManager => _user?.tipo == 'GERENTE' || _user?.tipo == 'ADMIN';
  bool get isAdmin => _user?.tipo == 'ADMIN';

  AuthProvider(this._authService) {
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
    _error = null;
    notifyListeners();
    
    try {
      final result = await _authService.login(email, password);
      _token = result['token'];
      _user = result['user'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _token!);
      // Idealmente salvar o user serializado ou buscar no perfil
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nomeCompleto,
    required String cpf,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(
        email: email,
        password: password,
        nomeCompleto: nomeCompleto,
        cpf: cpf,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
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

  Future<void> updateProfile({
    required String nomeCompleto,
    required String email,
  }) async {
    if (_user == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.updateProfile(
        id: _user!.id,
        nomeCompleto: nomeCompleto,
        email: email,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    if (_user == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteAccount(_user!.id);
      await logout();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
