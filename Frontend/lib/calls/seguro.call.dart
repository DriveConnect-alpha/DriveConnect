import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// seguro.call.dart
//
// Centralizes all insurance plan management HTTP calls.
// Follows the mapping of backend's `seguro.routes.ts`.
// ─────────────────────────────────────────────────────────────────────────────

class SeguroCall {
  /// Lista todos os planos de seguro ativos.
  /// ROUTE: GET /seguros
  /// AUTH: none (Público/Cliente)
  static Future<void> listar({
    required void Function(List<Map<String, dynamic>> planos) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>('/seguros');
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Cria um novo plano de seguro.
  /// ROUTE: POST /seguros
  /// AUTH: required (ADMIN ONLY)
  static Future<void> criar({
    required String nome,
    String? descricao,
    required double percentual,
    bool obrigatorio = false,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (nome.isEmpty) {
      onError('O nome do plano é obrigatório.');
      return;
    }

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/seguros',
        data: {
          'nome': nome,
          if (descricao != null) 'descricao': descricao,
          'percentual': percentual,
          'obrigatorio': obrigatorio,
        },
      );
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Atualiza um plano de seguro existente.
  /// ROUTE: PUT /seguros/:id
  /// AUTH: required (ADMIN ONLY)
  static Future<void> atualizar({
    required String planoId,
    String? nome,
    String? descricao,
    double? percentual,
    required void Function(Map<String, dynamic> planoAtualizado) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.put<Map<String, dynamic>>(
        '/seguros/$planoId',
        data: {
          if (nome != null) 'nome': nome,
          if (descricao != null) 'descricao': descricao,
          if (percentual != null) 'percentual': percentual,
        },
      );
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Desativa um plano de seguro (soft delete).
  /// ROUTE: DELETE /seguros/:id
  /// AUTH: required (ADMIN ONLY)
  static Future<void> desativar({
    required String planoId,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.delete<Map<String, dynamic>>('/seguros/$planoId');
      onSuccess(response.data!['mensagem'] as String? ?? 'Plano desativado.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
