import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// financeiro.call.dart
//
// Centralizes all financial management HTTP calls, such as refunds (estornos)
// and extra charges for reservations.
// Follows the mapping of backend's `financeiro.routes.ts`.
// ─────────────────────────────────────────────────────────────────────────────

class FinanceiroCall {
  /// Solicita o estorno de um pagamento vinculado a uma reserva.
  /// ROUTE: POST /pagamentos/:reservaId/estorno
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await FinanceiroCall.estornarPagamento(
  ///   reservaId: 'uuid-reserva',
  ///   onSuccess: (msg) => print(msg),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> estornarPagamento({
    required String reservaId,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/pagamentos/$reservaId/estorno',
      );
      
      onSuccess(response.data!['mensagem'] as String? ?? 'Estorno processado.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Cria uma cobrança extra para uma reserva (ex: multas, avarias, combustível).
  /// ROUTE: POST /reservas/:reservaId/cobranca-extra
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await FinanceiroCall.criarCobrancaExtra(
  ///   reservaId: 'uuid-reserva',
  ///   itens: [
  ///     {'descricao': 'Limpeza Pesada', 'valor': 150.0},
  ///     {'descricao': 'Combustível Faltante', 'valor': 80.5},
  ///   ],
  ///   onSuccess: (data) => print('Cobrança criada!'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> criarCobrancaExtra({
    required String reservaId,
    required List<Map<String, dynamic>> itens,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (itens.isEmpty) {
      onError('É necessário informar ao menos um item para a cobrança.');
      return;
    }

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/reservas/$reservaId/cobranca-extra',
        data: {'itens': itens},
      );
      
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
