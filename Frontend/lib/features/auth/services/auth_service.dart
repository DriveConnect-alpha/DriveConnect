import 'dart:async';
import '../../../core/models/usuario.dart';
import '../../../calls/user.call.dart';
import '../../../calls/cliente.call.dart';
import 'iauth_service.dart';

class AuthService implements IAuthService {
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final completer = Completer<Map<String, dynamic>>();

    await UserCall.login(
      email: email,
      senha: password,
      onSuccess: (userData) {
        completer.complete({
          'token': userData['token'],
          'user': Usuario.fromJson(userData),
        });
      },
      onError: (msg) {
        completer.completeError(Exception(msg));
      },
    );

    return completer.future;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String nomeCompleto,
    required String cpf,
  }) async {
    final completer = Completer<void>();

    await ClienteCall.register(
      email: email,
      senha: password,
      nomeCompleto: nomeCompleto,
      cpf: cpf,
      onSuccess: (_) {
        completer.complete();
      },
      onError: (msg) {
        completer.completeError(Exception(msg));
      },
    );

    return completer.future;
  }

  @override
  Future<Usuario> updateProfile({
    required String id,
    required String nomeCompleto,
    required String email,
  }) async {
    final completer = Completer<Usuario>();

    await ClienteCall.editarPerfil(
      nomeCompleto: nomeCompleto,
      onSuccess: (data) {
        completer.complete(Usuario.fromJson(data));
      },
      onError: (msg) {
        completer.completeError(Exception(msg));
      },
    );

    return completer.future;
  }

  @override
  Future<void> changePassword({
    required String id,
    required String newPassword,
  }) async {
    final completer = Completer<void>();
    await UserCall.trocarSenha(
      usuarioId: id,
      novaSenha: newPassword,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );
    return completer.future;
  }

  @override
  Future<String> updateProfilePhoto({
    required String id,
    required dynamic imageFile,
  }) async {
    final completer = Completer<String>();
    await UserCall.atualizarFotoPerfil(
      imageFile: imageFile,
      onSuccess: (url) => completer.complete(url),
      onError: (msg) => completer.completeError(Exception(msg)),
    );
    return completer.future;
  }

  @override
  Future<void> updatePreferences({
    required String id,
    required Map<String, dynamic> preferences,
  }) async {
    final completer = Completer<void>();
    await UserCall.atualizarPreferencias(
      preferencias: preferences,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );
    return completer.future;
  }

  @override
  Future<void> removeProfilePhoto({required String id}) async {
    final completer = Completer<void>();
    await UserCall.removerFotoPerfil(
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );
    return completer.future;
  }

  @override
  Future<void> deleteAccount(String id) async {
    final completer = Completer<void>();

    await ClienteCall.desativarMinhaConta(
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
