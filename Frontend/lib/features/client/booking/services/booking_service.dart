import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/models/reserva.dart';
import 'ibooking_service.dart';

class BookingService implements IBookingService {
  final ApiClient _apiClient;

  BookingService(this._apiClient);

  @override
  Future<Map<String, dynamic>> verificarDisponibilidade({
    required int modeloId,
    required String filialId,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.disponibilidade,
        queryParameters: {
          'modelo_id': modeloId,
          'filial_id': filialId,
          'data_inicio': dataInicio.toIso8601String(),
          'data_fim': dataFim.toIso8601String(),
        },
      );
      return response.data;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> iniciarPagamento({
    required int modeloId,
    required String filialRetiradaId,
    required String filialDevolucaoId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required String clienteId,
    required String planoSeguroId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.iniciarPagamento,
        data: {
          'modelo_id': modeloId,
          'filial_retirada_id': filialRetiradaId,
          'filial_devolucao_id': filialDevolucaoId,
          'data_inicio': dataInicio.toIso8601String(),
          'data_fim': dataFim.toIso8601String(),
          'cliente_id': clienteId,
          'plano_seguro_id': planoSeguroId,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  @override
  Future<Map<String, dynamic>> consultarStatusPagamento(String reservaId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.statusPagamento.replaceFirst('{reservaId}', reservaId),
      );
      return response.data;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  @override
  Future<List<Reserva>> getMyReservations() async {
     try {
      final response = await _apiClient.get('/reservas/minhas');
      return (response.data as List).map((r) => Reserva.fromJson(r)).toList();
    } catch (e) {
       throw ApiErrorHandler.handle(e);
    }
  }

  @override
  Future<void> cancelarReserva(String reservaId) async {
    try {
      await _apiClient.post('/reservas/$reservaId/cancelar');
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
