import 'dart:async';
import '../../../../core/models/reserva.dart';
import '../../../../calls/reserva.call.dart';
import 'ireservation_manager_service.dart';

class ReservationManagerService implements IReservationManagerService {
  @override
  Future<List<Reserva>> getManagerReservations({String? clienteId}) async {
    final completer = Completer<List<Reserva>>();

    await ReservaCall.listarReservas(
      clienteId: clienteId,
      onSuccess: (data) {
        final reservas = data.map((r) => Reserva.fromJson(r)).toList();
        completer.complete(reservas);
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> updateReservationStatus(String id, String status) async {
    // The backend handles status changes via specific endpoints (retirada, devolucao, cancelar)
    // rather than a generic status update. Map the status to the correct call.
    final completer = Completer<void>();

    switch (status) {
      case 'RESERVADA':
        // For testing/manual confirmation, we update the status to RESERVADA
        await ReservaCall.confirmarPagamentoManual(
          reservaId: id,
          onSuccess: (_) => completer.complete(),
          onError: (msg) => completer.completeError(Exception(msg)),
        );
        break;
      case 'ATIVA':
        await ReservaCall.confirmarRetirada(
          reservaId: id,
          onSuccess: (_) => completer.complete(),
          onError: (msg) => completer.completeError(Exception(msg)),
        );
        break;
      case 'FINALIZADA':
        await ReservaCall.confirmarDevolucao(
          reservaId: id,
          onSuccess: (_) => completer.complete(),
          onError: (msg) => completer.completeError(Exception(msg)),
        );
        break;
      case 'CANCELADA':
        await ReservaCall.cancelar(
          reservaId: id,
          onSuccess: (_) => completer.complete(),
          onError: (msg) => completer.completeError(Exception(msg)),
        );
        break;
      default:
        completer.completeError(Exception('Status inválido: $status'));
    }

    return completer.future;
  }

  @override
  Future<Map<String, dynamic>> createReservation({
    required String veiculoId,
    required String clienteId,
    required String filialRetiradaId,
    required String filialDevolucaoId,
    required String dataInicio,
    required String dataFim,
    String? planoSeguroId,
    String? metodoPagamento,
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    await ReservaCall.registrarReserva(
      veiculoId: veiculoId,
      clienteId: clienteId,
      filialRetiradaId: filialRetiradaId,
      filialDevolucaoId: filialDevolucaoId,
      dataInicio: dataInicio,
      dataFim: dataFim,
      planoSeguroId: planoSeguroId,
      metodoPagamento: metodoPagamento,
      onSuccess: (data) => completer.complete(data),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> cancelReservation({
    required String reservaId,
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    await ReservaCall.cancelar(
      reservaId: reservaId,
      onSuccess: (_) => onSuccess(),
      onError: (msg) => onError(msg),
    );
  }

  @override
  Future<void> updateReservation({
    required String reservaId,
    String? veiculoId,
    String? dataInicio,
    String? dataFim,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    await ReservaCall.atualizarReserva(
      reservaId: reservaId,
      veiculoId: veiculoId,
      dataInicio: dataInicio,
      dataFim: dataFim,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}
