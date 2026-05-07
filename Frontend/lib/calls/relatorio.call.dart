import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// relatorio.call.dart
//
// Centralizes all HTTP calls related to dashboards, charts, and reports.
// Uses the callback pattern: onSuccess and onError. No exceptions thrown to UI.
// ─────────────────────────────────────────────────────────────────────────────

class RelatorioCall {
  /// Busca os dados de faturamento (Lucros, Receitas, Qtd de Reservas)
  /// ROUTE: GET /relatorios/faturamento
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await RelatorioCall.faturamento(
  ///   dataInicio: '2023-01-01',
  ///   dataFim: '2023-12-31',
  ///   onSuccess: (data) => print('Faturamento Total: R\$ ${data['faturamentoTotal']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> faturamento({
    required String dataInicio, // Formato esperado: YYYY-MM-DD
    required String dataFim,    // Formato esperado: YYYY-MM-DD
    String? filialId,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (dataInicio.isEmpty || dataFim.isEmpty) {
      onError('Datas de início e fim são obrigatórias.');
      return;
    }

    try {
      final response = await dioClient.get<Map<String, dynamic>>(
        '/relatorios/faturamento',
        queryParameters: {
          'data_inicio': dataInicio,
          'data_fim': dataFim,
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

  /// Busca os dados de ocupação da frota (Disponíveis, Alugados, Manutenção)
  /// ROUTE: GET /relatorios/ocupacao
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await RelatorioCall.ocupacao(
  ///   dataInicio: '2023-01-01',
  ///   dataFim: '2023-12-31',
  ///   onSuccess: (data) => print('Taxa de Ocupação: ${data['taxaOcupacao']}%'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> ocupacao({
    required String dataInicio,
    required String dataFim,
    String? filialId,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (dataInicio.isEmpty || dataFim.isEmpty) {
      onError('Datas de início e fim são obrigatórias.');
      return;
    }

    try {
      final response = await dioClient.get<Map<String, dynamic>>(
        '/relatorios/ocupacao',
        queryParameters: {
          'data_inicio': dataInicio,
          'data_fim': dataFim,
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

  /// Busca os dados operacionais (Retiradas, Devoluções, Atrasos)
  /// ROUTE: GET /relatorios/operacao
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await RelatorioCall.operacao(
  ///   dataInicio: '2023-01-01',
  ///   dataFim: '2023-12-31',
  ///   onSuccess: (data) => print('Retiradas no período: ${data['retiradas']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> operacao({
    required String dataInicio,
    required String dataFim,
    String? filialId,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    if (dataInicio.isEmpty || dataFim.isEmpty) {
      onError('Datas de início e fim são obrigatórias.');
      return;
    }

    try {
      final response = await dioClient.get<Map<String, dynamic>>(
        '/relatorios/operacao',
        queryParameters: {
          'data_inicio': dataInicio,
          'data_fim': dataFim,
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
}
