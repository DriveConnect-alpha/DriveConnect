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
  /// Inicia o processo de pagamento para uma reserva.
  /// O backend gerará um link de checkout ou um PIX via InfinitePay.
  /// ROUTE: POST /pagamento/iniciar
  /// AUTH: required (Cliente, Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await PagamentoCall.iniciarPagamento(
  ///   reservaId: 'uuid-reserva',
  ///   onSuccess: (data) {
  ///     final checkoutUrl = data['url']; // URL para redirecionar o cliente
  ///     print('Link de pagamento: $checkoutUrl');
  ///   },
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> iniciarPagamento({
    required String reservaId,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (reservaId.isEmpty) {
      onError('O ID da reserva é obrigatório para iniciar o pagamento.');
      return;
    }

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/pagamento/iniciar',
        data: {'reservaId': reservaId},
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
