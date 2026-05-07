import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// gerente.call.dart
//
// Centralizes all administrative and manager-level HTTP calls to the DriveConnect backend.
// Uses the callback pattern: onSuccess and onError. No exceptions thrown to UI.
// ─────────────────────────────────────────────────────────────────────────────

class GerenteCall {
  /// Registra um novo gerente.
  /// ROUTE: POST /usuarios/gerentes
  /// AUTH: required (Admin ou configuração inicial)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await GerenteCall.registerGerente(
  ///   email: 'gerente@drive.com',
  ///   senha: '123',
  ///   nomeCompleto: 'João Gerente',
  ///   onSuccess: (data) => print('Gerente criado: ${data['id']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> registerGerente({
    required String email,
    required String senha,
    required String nomeCompleto,
    String? filialId,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (email.isEmpty || senha.isEmpty || nomeCompleto.isEmpty) {
      onError('Os campos email, senha e nome completo são obrigatórios.');
      return;
    }

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/usuarios/gerentes',
        data: {
          'email': email,
          'senha': senha,
          'nome_completo': nomeCompleto,
          if (filialId != null) 'filial_id': filialId,
        },
      );
      
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Lista todos os clientes do sistema.
  /// ROUTE: GET /usuarios/clientes
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await GerenteCall.listarClientes(
  ///   onSuccess: (clientes) => print('Total de clientes: ${clientes.length}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> listarClientes({
    required void Function(List<Map<String, dynamic>> clientes) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>(
        '/usuarios/clientes',
      );
      
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Busca um cliente específico pelo ID.
  /// ROUTE: GET /usuarios/clientes/:id
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await GerenteCall.buscarCliente(
  ///   clienteId: 'uuid',
  ///   onSuccess: (cliente) => print('Cliente: ${cliente['nome_completo']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> buscarCliente({
    required String clienteId,
    required void Function(Map<String, dynamic> cliente) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (clienteId.isEmpty) {
      onError('ID do cliente é obrigatório.');
      return;
    }

    try {
      final response = await dioClient.get<Map<String, dynamic>>(
        '/usuarios/clientes/$clienteId',
      );
      
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Edita os dados de um cliente específico.
  /// ROUTE: PUT /usuarios/clientes/:id
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await GerenteCall.editarCliente(
  ///   clienteId: 'uuid',
  ///   nomeCompleto: 'Novo Nome',
  ///   onSuccess: (cliente) => print('Atualizado com sucesso!'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> editarCliente({
    required String clienteId,
    String? nomeCompleto,
    String? rg,
    String? cnh,
    required void Function(Map<String, dynamic> clienteAtualizado) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (clienteId.isEmpty) {
      onError('ID do cliente é obrigatório.');
      return;
    }

    try {
      final response = await dioClient.put<Map<String, dynamic>>(
        '/usuarios/clientes/$clienteId',
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

  /// Desativa/Deleta um usuário do sistema.
  /// ROUTE: DELETE /usuarios/:id
  /// AUTH: required (Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await GerenteCall.desativarUsuario(
  ///   usuarioId: 'uuid',
  ///   onSuccess: (msg) => print(msg),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> desativarUsuario({
    required String usuarioId,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (usuarioId.isEmpty) {
      onError('ID do usuário é obrigatório.');
      return;
    }

    try {
      final response = await dioClient.delete<Map<String, dynamic>>(
        '/usuarios/$usuarioId',
      );
      
      onSuccess(response.data!['mensagem'] as String? ?? 'Usuário desativado com sucesso.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
