import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// reserva.call.dart
//
// Handles all reservation-related HTTP calls to the DriveConnect backend.
// Covers availability checks, booking creation, check-in/out, and management.
// Uses the callback pattern: onSuccess and onError. No exceptions thrown to UI.
// ─────────────────────────────────────────────────────────────────────────────

class ReservaCall {
  /// Verifica se há veículos disponíveis para um modelo e período específicos.
  /// ROUTE: GET /reservas/disponibilidade
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await ReservaCall.checarDisponibilidade(
  ///   modeloId: 5,
  ///   filialId: 'uuid-filial',
  ///   dataInicio: '2024-06-01T10:00:00Z',
  ///   dataFim: '2024-06-10T10:00:00Z',
  ///   onSuccess: (data) => print('Preço: ${data['preco_total']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> checarDisponibilidade({
    required int modeloId,
    required String filialId,
    required String dataInicio,
    required String dataFim,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<Map<String, dynamic>>(
        '/reservas/disponibilidade',
        queryParameters: {
          'modelo_id': modeloId,
          'filial_id': filialId,
          'data_inicio': dataInicio,
          'data_fim': dataFim,
        },
      );

      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Registra uma nova reserva pendente (inicia fluxo de pagamento).
  /// ROUTE: POST /reservas
  /// AUTH: required (CLIENTE)
  static Future<void> registrarReserva({
    required String veiculoId,
    required String filialRetiradaId,
    required String filialDevolucaoId,
    required String dataInicio,
    required String dataFim,
    String? planoSeguroId,
    String? clienteId,
    String? metodoPagamento,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/reservas',
        data: {
          'veiculo_id': veiculoId,
          'filial_retirada_id': filialRetiradaId,
          'filial_devolucao_id': filialDevolucaoId,
          'data_inicio': dataInicio,
          'data_fim': dataFim,
          if (planoSeguroId != null) 'plano_seguro_id': planoSeguroId,
          if (clienteId != null) 'cliente_id': clienteId,
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

  /// Lista reservas do sistema com filtros opcionais.
  /// ROUTE: GET /reservas
  /// AUTH: required (Gerente, Admin)
  static Future<void> listarReservas({
    String? status,
    String? clienteId,
    required void Function(List<Map<String, dynamic>> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>(
        '/reservas',
        queryParameters: {
          if (status != null) 'status': status,
          if (clienteId != null) 'cliente_id': clienteId,
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

  /// Lista as próprias reservas do cliente logado.
  /// ROUTE: GET /reservas/minhas
  /// AUTH: required (CLIENTE)
  static Future<void> listarMinhasReservas({
    String? status,
    required void Function(List<Map<String, dynamic>> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>(
        '/reservas/minhas',
        queryParameters: {
          if (status != null) 'status': status,
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

  /// Detalha uma reserva específica.
  /// ROUTE: GET /reservas/:id
  static Future<void> detalhar({
    required String reservaId,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<Map<String, dynamic>>(
        '/reservas/$reservaId',
      );

      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Estende o período de uma reserva.
  /// ROUTE: POST /reservas/:id/estender
  static Future<void> estender({
    required String reservaId,
    required String novaDataFim,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/reservas/$reservaId/estender',
        data: {'nova_data_fim': novaDataFim},
      );

      onSuccess(response.data!['mensagem'] as String? ?? 'Reserva estendida.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Confirma a retirada (check-in) do veículo.
  /// ROUTE: POST /reservas/:id/retirada
  static Future<void> confirmarRetirada({
    required String reservaId,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/reservas/$reservaId/retirada',
      );

      onSuccess(
        response.data!['mensagem'] as String? ?? 'Retirada confirmada.',
      );
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Confirma a devolução (check-out) do veículo.
  /// ROUTE: POST /reservas/:id/devolucao
  static Future<void> confirmarDevolucao({
    required String reservaId,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/reservas/$reservaId/devolucao',
      );

      onSuccess(
        response.data!['mensagem'] as String? ?? 'Devolução registrada.',
      );
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Cancela uma reserva.
  /// ROUTE: POST /reservas/:id/cancelar
  static Future<void> cancelar({
    required String reservaId,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/reservas/$reservaId/cancelar',
      );

      onSuccess(response.data!['mensagem'] as String? ?? 'Reserva cancelada.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Confirma manualmente o pagamento de uma reserva.
  /// ROUTE: POST /reservas/:id/confirmar-pagamento
  /// AUTH: required (Gerente, Admin)
  static Future<void> confirmarPagamentoManual({
    required String reservaId,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/reservas/$reservaId/confirmar-pagamento',
      );

      onSuccess(
        response.data!['mensagem'] as String? ?? 'Pagamento confirmado.',
      );
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Atualiza uma reserva pendente (veículo e datas).
  /// ROUTE: PATCH /reservas/:id
  /// AUTH: required (Gerente, Admin, Cliente dono)
  static Future<void> atualizarReserva({
    required String reservaId,
    String? veiculoId,
    String? dataInicio,
    String? dataFim,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.patch<Map<String, dynamic>>(
        '/reservas/$reservaId',
        data: {
          if (veiculoId != null) 'veiculo_id': veiculoId,
          if (dataInicio != null) 'data_inicio': dataInicio,
          if (dataFim != null) 'data_fim': dataFim,
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

