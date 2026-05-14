import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// user.call.dart
//
// Centralizes all authentication and security HTTP calls to the DriveConnect backend.
// Uses the callback pattern: onSuccess and onError. No exceptions thrown to UI.
// ─────────────────────────────────────────────────────────────────────────────

class UserCall {
  /// Autentica um usuário existente e configura sua identidade no client.
  /// ROUTE: POST /usuarios/login
  /// AUTH: none
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await UserCall.login(
  ///   email: 'joao@email.com',
  ///   senha: '123',
  ///   onSuccess: (user) => print('Bem-vindo(a), ${user['nome_completo']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> login({
    required String email,
    required String senha,
    required void Function(Map<String, dynamic> user) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (email.isEmpty || senha.isEmpty) {
      onError('Email e senha são obrigatórios.');
      return;
    }

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/usuarios/login',
        data: {
          'email': email,
          'senha': senha,
        },
      );
      
      final userData = response.data!;
      final token = userData['token'] as String?;
      
      if (token == null || token.isEmpty) {
        onError('Resposta do servidor inválida: token ausente.');
        return;
      }
      
      // Configura identidade JWT no core após login com sucesso
      setIdentity(
        token: token,
        usuarioId: userData['id'] as String,
        tipo: userData['tipo'] as String,
        perfilId: userData['perfilId'] as String?,
        filialId: userData['filialId'] as String?,
      );
      
      onSuccess(userData);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Solicita recuperação de senha via e-mail.
  /// ROUTE: POST /usuarios/esqueci-senha
  /// AUTH: none
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await UserCall.esqueciSenha(
  ///   email: 'joao@email.com',
  ///   onSuccess: (mensagem) => print(mensagem),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> esqueciSenha({
    required String email,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (email.isEmpty) {
      onError('O e-mail é obrigatório.');
      return;
    }

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/usuarios/esqueci-senha',
        data: {'email': email},
      );
      
      onSuccess(response.data!['mensagem'] as String? ?? 'Instruções enviadas.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Redefine a senha utilizando um token.
  /// ROUTE: POST /usuarios/redefinir-senha
  /// AUTH: none
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await UserCall.redefinirSenha(
  ///   token: 'abc123xyz',
  ///   novaSenha: 'nova-senha-123',
  ///   onSuccess: (mensagem) => print(mensagem),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> redefinirSenha({
    required String token,
    required String novaSenha,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (token.isEmpty || novaSenha.isEmpty) {
      onError('Token e nova senha são obrigatórios.');
      return;
    }

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/usuarios/redefinir-senha',
        data: {'token': token, 'nova_senha': novaSenha},
      );
      
      onSuccess(response.data!['mensagem'] as String? ?? 'Senha redefinida com sucesso.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Altera a senha do usuário logado.
  /// ROUTE: PATCH /usuarios/:id/senha
  /// AUTH: required
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await UserCall.trocarSenha(
  ///   usuarioId: 'uuid',
  ///   novaSenha: 'minha-nova-senha',
  ///   onSuccess: (mensagem) => print(mensagem),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> trocarSenha({
    required String usuarioId,
    required String novaSenha,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (usuarioId.isEmpty || novaSenha.isEmpty) {
      onError('ID do usuário e nova senha são obrigatórios.');
      return;
    }

    try {
      final response = await dioClient.patch<Map<String, dynamic>>(
        '/usuarios/$usuarioId/senha',
        data: {'nova_senha': novaSenha},
      );
      
      onSuccess(response.data!['mensagem'] as String? ?? 'Senha alterada com sucesso.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
