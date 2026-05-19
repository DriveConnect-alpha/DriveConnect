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

  Future<void> cancelReservation({
    required String reservaId,
    required void Function() onSuccess,
    required void Function(String message) onError,
  });

  Future<void> updateReservation({
    required String reservaId,
    String? veiculoId,
    String? dataInicio,
    String? dataFim,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  });
}
