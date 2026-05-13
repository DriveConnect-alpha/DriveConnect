import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// cliente.call.dart
//
// Centralizes all client-profile HTTP calls to the DriveConnect backend.
// Uses the callback pattern: onSuccess and onError. No exceptions thrown to UI.
// ─────────────────────────────────────────────────────────────────────────────

class ClienteCall {
  /// Registra um novo cliente.
  /// ROUTE: POST /usuarios/clientes
  /// AUTH: none
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await ClienteCall.register(
  ///   email: 'joao@email.com',
  ///   senha: '123',
  ///   nomeCompleto: 'João Cliente',
  ///   cpf: '111.111.111-11',
  ///   rg: 'MG-12345',
  ///   cnh: '12345678901',
  ///   onSuccess: (data) => print('Cliente cadastrado! ID: ${data['id']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> register({
    required String email,
    required String senha,
    required String nomeCompleto,
    required String cpf,
    String? rg,
    String? cnh,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (email.isEmpty || senha.isEmpty || nomeCompleto.isEmpty || cpf.isEmpty) {
      onError('Os campos email, senha, nome completo e CPF são obrigatórios.');
      return;
    }

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/usuarios/clientes',
        data: {
          'email': email,
          'senha': senha,
          'nome_completo': nomeCompleto,
          'cpf': cpf,
          if (rg != null && rg.isNotEmpty) 'rg': rg,
          if (cnh != null && cnh.isNotEmpty) 'cnh': cnh,
        },
      );
      
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Busca o perfil do cliente atualmente logado.
  /// ROUTE: GET /usuarios/clientes/me
  /// AUTH: required
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await ClienteCall.meuPerfil(
  ///   onSuccess: (perfil) => print('Olá, ${perfil['nome_completo']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> meuPerfil({
    required void Function(Map<String, dynamic> perfil) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<Map<String, dynamic>>(
        '/usuarios/clientes/me',
      );
      
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Edita os dados do perfil do cliente atualmente logado.
  /// ROUTE: PUT /usuarios/clientes/me
  /// AUTH: required
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await ClienteCall.editarPerfil(
  ///   nomeCompleto: 'Novo Nome do Cliente',
  ///   onSuccess: (perfilAtualizado) => print('Perfil atualizado!'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> editarPerfil({
    String? nomeCompleto,
    String? rg,
    String? cnh,
    required void Function(Map<String, dynamic> perfilAtualizado) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.put<Map<String, dynamic>>(
        '/usuarios/clientes/me',
        data: {
          if (nomeCompleto != null) 'nome_completo': nomeCompleto,
          if (rg != null) 'rg': rg,
          if (cnh != null) 'cnh': cnh,
        },
      );
      
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
