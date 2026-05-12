import 'dart:async';
import '../../../../core/models/reserva.dart';
import '../../../../calls/reserva.call.dart';
import '../../../../calls/pagamento.call.dart';
import 'ibooking_service.dart';

class BookingService implements IBookingService {
  @override
  Future<Map<String, dynamic>> verificarDisponibilidade({
    required int modeloId,
    required String filialId,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    await ReservaCall.checarDisponibilidade(
      modeloId: modeloId,
      filialId: filialId,
      dataInicio: dataInicio.toIso8601String(),
      dataFim: dataFim.toIso8601String(),
      onSuccess: (data) => completer.complete(data),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
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
    final completer = Completer<Map<String, dynamic>>();

    await PagamentoCall.iniciarPagamento(
      modeloId: modeloId,
      filialRetiradaId: filialRetiradaId,
      filialDevolucaoId: filialDevolucaoId,
      dataInicio: dataInicio.toIso8601String(),
      dataFim: dataFim.toIso8601String(),
      clienteId: clienteId,
      planoSeguroId: planoSeguroId,
      onSuccess: (data) => completer.complete(data),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<Map<String, dynamic>> consultarStatusPagamento(String reservaId) async {
    final completer = Completer<Map<String, dynamic>>();

    await PagamentoCall.consultarStatus(
      reservaId: reservaId,
      onSuccess: (data) => completer.complete(data),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<List<Reserva>> getMyReservations() async {
    final completer = Completer<List<Reserva>>();

    await ReservaCall.listarReservas(
      onSuccess: (data) {
        final reservas = data.map((r) => Reserva.fromJson(r)).toList();
        completer.complete(reservas);
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> cancelarReserva(String reservaId) async {
    final completer = Completer<void>();

    await ReservaCall.cancelar(
      reservaId: reservaId,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
