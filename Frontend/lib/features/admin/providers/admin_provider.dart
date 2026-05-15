import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../services/iadmin_service.dart';

class AdminProvider extends ChangeNotifier {
  final IAdminService _adminService;

  AdminProvider(this._adminService);

  List<AdminUser> _users = [];
  bool _isLoading = false;
  String? _error;

  List<AdminUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _adminService.listUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(String id, {String? nome, String? email, String? novaSenha}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.updateUser(id, nome: nome, email: email, novaSenha: novaSenha);
      await fetchUsers(); // Recarrega a lista
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registerManager({
    required String email,
    required String password,
    required String nomeCompleto,
    required String filialId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.registerManager(
        email: email,
        password: password,
        nomeCompleto: nomeCompleto,
        filialId: filialId,
      );
      await fetchUsers(); // Recarrega a lista após cadastrar
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.deleteUser(id);
      await fetchUsers();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
