import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../constants/app_constants.dart';
import '../../features/auth/services/iauth_service.dart';
import '../../calls/api_core.dart';
import '../../services/fcm_service.dart';

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
    final userJson = prefs.getString(AppConstants.userKey);
    
    if (_token != null && userJson != null) {
      try {
        _user = Usuario.fromJson(jsonDecode(userJson));
        // Restore identity in api_core so calls layer is authenticated
        setIdentity(
          token: _token!,
          usuarioId: _user!.id,
          tipo: _user!.tipo,
          perfilId: _user!.perfilId,
          filialId: _user!.filialId,
        );
        await FcmService().onUserAuthenticated();
      } catch (_) {
        _token = null;
        _user = null;
      }
    }
    
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
      
      // Persist auth data for session restore
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _token!);
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      
      // Note: setIdentity is already called inside UserCall.login
      await FcmService().onUserAuthenticated();
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
    // Remove FCM token BEFORE clearing identity (needs auth headers)
    await FcmService().onUserLogout();
    _token = null;
    _user = null;
    clearIdentity(); // Clear JWT from api_core
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
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
      
      // Update persisted user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.changePassword(id: _user!.id, newPassword: newPassword);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfilePhoto(dynamic imageFile) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final newPhotoUrl = await _authService.updateProfilePhoto(id: _user!.id, imageFile: imageFile);
      
      // Atualiza o objeto do usuário localmente
      _user = Usuario(
        id: _user!.id,
        email: _user!.email,
        nome: _user!.nome,
        tipo: _user!.tipo,
        perfilId: _user!.perfilId,
        filialId: _user!.filialId,
        imagemUrl: newPhotoUrl,
        preferencias: _user!.preferencias,
        criadoEm: _user!.criadoEm,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeProfilePhoto() async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.removeProfilePhoto(id: _user!.id);
      
      // Atualiza o objeto do usuário localmente retirando a foto
      _user = Usuario(
        id: _user!.id,
        email: _user!.email,
        nome: _user!.nome,
        tipo: _user!.tipo,
        perfilId: _user!.perfilId,
        filialId: _user!.filialId,
        imagemUrl: null,
        preferencias: _user!.preferencias,
        criadoEm: _user!.criadoEm,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> newPrefs) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updatePreferences(id: _user!.id, preferences: newPrefs);
      
      // Atualiza o objeto do usuário localmente
      _user = Usuario(
        id: _user!.id,
        email: _user!.email,
        nome: _user!.nome,
        tipo: _user!.tipo,
        perfilId: _user!.perfilId,
        filialId: _user!.filialId,
        imagemUrl: _user!.imagemUrl,
        preferencias: newPrefs,
        criadoEm: _user!.criadoEm,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
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
