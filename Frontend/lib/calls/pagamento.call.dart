import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// pagamento.call.dart
//
// Handles the payment/checkout flow integration with the backend,
// specifically for the InfinitePay gateway integration.
// Follows the mapping of backend's `payment.routes.ts`.
// ─────────────────────────────────────────────────────────────────────────────

class PagamentoCall {
  static Future<void> iniciarPagamento({
    required int modeloId,
    required String filialRetiradaId,
    required String filialDevolucaoId,
    required String dataInicio,
    required String dataFim,
    required String clienteId,
    required String planoSeguroId,
    String? metodoPagamento,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/pagamento/iniciar',
        data: {
          'modelo_id': modeloId,
          'filial_retirada_id': filialRetiradaId,
          'filial_devolucao_id': filialDevolucaoId,
          'data_inicio': dataInicio,
          'data_fim': dataFim,
          'cliente_id': clienteId,
          'plano_seguro_id': planoSeguroId,
          if (metodoPagamento != null) 'metodo_pagamento': metodoPagamento,
        },
      );
      
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Consulta o status atual do pagamento de uma reserva.
  /// Útil para polling ou verificação manual após o retorno do checkout.
  /// ROUTE: GET /pagamento/status/:reservaId
  /// AUTH: required (Cliente, Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await PagamentoCall.consultarStatus(
  ///   reservaId: 'uuid-reserva',
  ///   onSuccess: (data) => print('Status: ${data['status']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> consultarStatus({
    required String reservaId,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<Map<String, dynamic>>(
        '/pagamento/status/$reservaId',
      );
      
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
