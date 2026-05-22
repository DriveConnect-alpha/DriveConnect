import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// filial.call.dart
//
// Centralizes all branch (filial) and manager management HTTP calls.
// Follows the mapping of backend's `filial.routes.ts`.
// ─────────────────────────────────────────────────────────────────────────────

class FilialCall {
  /// Lista todas as filiais cadastradas.
  /// ROUTE: GET /filiais
  /// AUTH: required (Cliente, Gerente, Admin)
  static Future<void> listar({
    required void Function(List<Map<String, dynamic>> filiais) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>('/filiais');
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Busca detalhes de uma filial específica.
  /// ROUTE: GET /filiais/:id
  /// AUTH: required (Cliente, Gerente, Admin)
  static Future<void> detalhar({
    required String filialId,
    required void Function(Map<String, dynamic> filial) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<Map<String, dynamic>>('/filiais/$filialId');
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Registra uma nova filial no sistema.
  /// ROUTE: POST /filiais
  /// AUTH: required (ADMIN ONLY)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await FilialCall.registrar(
  ///   nome: 'DriveConnect Matriz',
  ///   cidade: 'São Paulo',
  ///   uf: 'SP',
  ///   onSuccess: (data) => print('Filial criada!'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> registrar({
    required String nome,
    String? cep,
    String? uf,
    String? cidade,
    String? bairro,
    String? rua,
    String? numero,
    String? complemento,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (nome.isEmpty) {
      onError('O nome da filial é obrigatório.');
      return;
    }

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/filiais',
        data: {
          'nome': nome,
          if (cep != null) 'cep': cep,
          if (uf != null) 'uf': uf,
          if (cidade != null) 'cidade': cidade,
          if (bairro != null) 'bairro': bairro,
          if (rua != null) 'rua': rua,
          if (numero != null) 'numero': numero,
          if (complemento != null) 'complemento': complemento,
        },
      );
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Edita os dados de uma filial existente.
  /// ROUTE: PUT /filiais/:id
  /// AUTH: required (Admin ou Gerente da própria filial)
  static Future<void> editar({
    required String filialId,
    String? nome,
    String? cep,
    String? uf,
    String? cidade,
    String? bairro,
    String? rua,
    String? numero,
    String? complemento,
    required void Function(Map<String, dynamic> filialAtualizada) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.put<Map<String, dynamic>>(
        '/filiais/$filialId',
        data: {
          if (nome != null) 'nome': nome,
          if (cep != null) 'cep': cep,
          if (uf != null) 'uf': uf,
          if (cidade != null) 'cidade': cidade,
          if (bairro != null) 'bairro': bairro,
          if (rua != null) 'rua': rua,
          if (numero != null) 'numero': numero,
          if (complemento != null) 'complemento': complemento,
        },
      );
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Desativa uma filial (soft delete).
  /// ROUTE: DELETE /filiais/:id
  /// AUTH: required (ADMIN ONLY)
  static Future<void> desativar({
    required String filialId,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.delete<Map<String, dynamic>>('/filiais/$filialId');
      onSuccess(response.data!['mensagem'] as String? ?? 'Filial desativada.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Lista todos os gerentes do sistema.
  /// ROUTE: GET /gerentes
  /// AUTH: required (ADMIN ONLY)
  static Future<void> listarGerentes({
    required void Function(List<Map<String, dynamic>> gerentes) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>('/gerentes');
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Busca o perfil do gerente atualmente logado.
  /// ROUTE: GET /gerentes/me
  /// AUTH: required (GERENTE)
  static Future<void> meuPerfilGerente({
    required void Function(Map<String, dynamic> perfil) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<Map<String, dynamic>>('/gerentes/me');
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
