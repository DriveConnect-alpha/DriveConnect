import '../../../../core/models/reserva.dart';

abstract class IBookingService {
  Future<Map<String, dynamic>> verificarDisponibilidade({
    required int modeloId,
    required String filialId,
    required DateTime dataInicio,
    required DateTime dataFim,
  });

  Future<Map<String, dynamic>> iniciarPagamento({
    required int modeloId,
    required String filialRetiradaId,
    required String filialDevolucaoId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required String clienteId,
    required String planoSeguroId,
  });

  Future<Map<String, dynamic>> consultarStatusPagamento(String reservaId);
  
  Future<List<Reserva>> getMyReservations();
}
