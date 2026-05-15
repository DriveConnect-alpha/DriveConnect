import 'dart:async';
import '../models/admin_user.dart';
import '../../../calls/gerente.call.dart';
import 'iadmin_service.dart';

class AdminService implements IAdminService {
  @override
  Future<List<AdminUser>> listUsers() async {
    final completer = Completer<List<AdminUser>>();

    await GerenteCall.listarUsuarios(
      onSuccess: (data) {
        final users = data.map((json) => AdminUser.fromJson(json)).toList();
        completer.complete(users);
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> updateUser(String id, {String? nome, String? email, String? novaSenha}) async {
    final completer = Completer<void>();

    if (novaSenha != null && novaSenha.isNotEmpty) {
      // Password change uses a different endpoint
      await completer.future;
      return;
    }

    await GerenteCall.editarCliente(
      clienteId: id,
      nomeCompleto: nome,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> registerManager({
    required String email,
    required String password,
    required String nomeCompleto,
    required String filialId,
  }) async {
    final completer = Completer<void>();

    await GerenteCall.registerGerente(
      email: email,
      senha: password,
      nomeCompleto: nomeCompleto,
      filialId: filialId,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> deleteUser(String id) async {
    final completer = Completer<void>();

    await GerenteCall.desativarUsuario(
      usuarioId: id,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
