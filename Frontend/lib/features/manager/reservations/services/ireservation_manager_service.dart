import '../../../../core/models/reserva.dart';

abstract class IReservationManagerService {
  Future<List<Reserva>> getManagerReservations({String? clienteId});
  Future<void> updateReservationStatus(String id, String status);
  Future<Map<String, dynamic>> createReservation({
    required String veiculoId,
    required String clienteId,
    required String filialRetiradaId,
    required String filialDevolucaoId,
    required String dataInicio,
    required String dataFim,
    String? planoSeguroId,
    String? metodoPagamento,
  });
}
