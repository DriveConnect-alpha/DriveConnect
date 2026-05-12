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
          'user': Usuario(
            id: userData['id'] ?? '',
            email: userData['email'] ?? '',
            nome: userData['nome'] ?? 'Usuário',
            tipo: userData['tipo'] ?? 'CLIENTE',
            criadoEm: userData['criado_em'] != null
                ? DateTime.parse(userData['criado_em'])
                : DateTime.now(),
          ),
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
      rg: '',
      cnh: '',
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
        completer.complete(Usuario(
          id: data['usuario_id'] ?? id,
          email: email,
          nome: data['nome_completo'] ?? nomeCompleto,
          tipo: 'CLIENTE',
          criadoEm: data['criado_em'] != null
              ? DateTime.parse(data['criado_em'])
              : DateTime.now(),
        ));
      },
      onError: (msg) {
        completer.completeError(Exception(msg));
      },
    );

    return completer.future;
  }

  @override
  Future<void> deleteAccount(String id) async {
    final completer = Completer<void>();

    await UserCall.trocarSenha(
      usuarioId: id,
      novaSenha: '',
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
