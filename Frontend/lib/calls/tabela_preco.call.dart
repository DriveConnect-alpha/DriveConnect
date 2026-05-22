import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// tabela_preco.call.dart
//
// Centralizes all price table management HTTP calls.
// Follows the mapping of backend's `tabelaPreco.routes.ts`.
// ─────────────────────────────────────────────────────────────────────────────

class TabelaPrecoCall {
  /// Lista as tabelas de preço cadastradas.
  /// ROUTE: GET /tabelas-preco
  /// AUTH: required (Gerente, Admin)
  static Future<void> listar({
    String? filialId,
    int? tipoCarroId,
    required void Function(List<Map<String, dynamic>> tabelas) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>(
        '/tabelas-preco',
        queryParameters: {
          if (filialId != null) 'filial_id': filialId,
          if (tipoCarroId != null) 'tipo_carro_id': tipoCarroId,
        },
      );
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Busca detalhes de uma tabela de preço específica.
  /// ROUTE: GET /tabelas-preco/:id
  static Future<void> buscar({
    required int id,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<Map<String, dynamic>>('/tabelas-preco/$id');
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Registra uma nova tabela de preço.
  /// ROUTE: POST /tabelas-preco
  /// AUTH: required (ADMIN ONLY)
  static Future<void> registrar({
    required int tipoCarroId,
    required String filialId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required double valorDiaria,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/tabelas-preco',
        data: {
          'tipo_carro_id': tipoCarroId,
          'filial_id': filialId,
          'data_inicio': dataInicio.toIso8601String().split('T')[0],
          'data_fim': dataFim.toIso8601String().split('T')[0],
          'valor_diaria': valorDiaria,
        },
      );
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Edita uma tabela de preço existente.
  /// ROUTE: PUT /tabelas-preco/:id
  static Future<void> editar({
    required int id,
    DateTime? dataInicio,
    DateTime? dataFim,
    double? valorDiaria,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.put<Map<String, dynamic>>(
        '/tabelas-preco/$id',
        data: {
          if (dataInicio != null) 'data_inicio': dataInicio.toIso8601String().split('T')[0],
          if (dataFim != null) 'data_fim': dataFim.toIso8601String().split('T')[0],
          if (valorDiaria != null) 'valor_diaria': valorDiaria,
        },
      );
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Remove uma tabela de preço.
  /// ROUTE: DELETE /tabelas-preco/:id
  static Future<void> remover({
    required int id,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.delete<Map<String, dynamic>>('/tabelas-preco/$id');
      onSuccess(response.data!['mensagem'] as String? ?? 'Tabela de preço removida.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
