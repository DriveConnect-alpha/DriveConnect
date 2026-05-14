import '../../../../core/models/reserva.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/models/modelo.dart';
import 'ibooking_service.dart';

class MockBookingService implements IBookingService {
  @override
  Future<Map<String, dynamic>> verificarDisponibilidade({
    required int modeloId,
    required String filialId,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return {'disponivel': true, 'veiculo_id': 'mock-veiculo-123'};
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
    String? metodoPagamento,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'id': 'mock-reserva-456',
      'payment_url': 'https://mock.payment.link',
      'order_nsu': 'MOCK123'
    };
  }

  @override
  Future<Map<String, dynamic>> consultarStatusPagamento(String reservaId) async {
    await Future.delayed(const Duration(seconds: 2));
    return {'status': 'PAID'};
  }

  @override
  Future<List<Reserva>> getMyReservations() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Reserva(
        id: '12345678-90ab-cdef-1234-567890abcdef',
        dataInicio: DateTime.now().add(const Duration(days: 1)),
        dataFim: DateTime.now().add(const Duration(days: 5)),
        status: 'RESERVADA',
        valorTotal: 850.00,
        veiculo: Veiculo(
          id: 'v1',
          placa: 'MOCK-001',
          cor: 'Prata',
          ano: 2023,
          status: 'DISPONIVEL',
          criadoEm: DateTime.now(),
          filialId: 'f1',
          modeloId: 1,
          modelo: Modelo(
            id: 1,
            nome: 'Corolla',
            marca: 'Toyota',
          ),
        ),
      ),
    ];
  }

  @override
  Future<void> cancelarReserva(String reservaId) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<List<Map<String, dynamic>>> getOccupiedDates(String veiculoId) async {
    return [];
  }

  @override
  Future<void> estenderReserva(String reservaId, DateTime novaDataFim) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
