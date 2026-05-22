import '../../../../core/models/reserva.dart';
import '../../../../core/models/cliente.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/models/modelo.dart';
import 'ireservation_manager_service.dart';

class MockReservationManagerService implements IReservationManagerService {
  @override
  Future<List<Reserva>> getManagerReservations({String? clienteId}) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Reserva(
        id: 'mock-1',
        status: 'PENDENTE',
        dataInicio: DateTime.now().add(const Duration(days: 2)),
        dataFim: DateTime.now().add(const Duration(days: 5)),
        cliente: Cliente(
          id: 'c1',
          nomeCompleto: 'João Silva',
          cpf: '123.456.789-00',
          usuarioId: 'u1',
          criadoEm: DateTime.now(),
        ),
        veiculo: Veiculo(
          id: 'v1',
          placa: 'ABC-1234',
          ano: 2022,
          status: 'DISPONIVEL',
          criadoEm: DateTime.now(),
          modelo: Modelo(id: 1, nome: 'Onix', marca: 'Chevrolet'),
        ),
      ),
    ];
  }

  @override
  Future<void> updateReservationStatus(String id, String status) async {
    await Future.delayed(const Duration(milliseconds: 500));
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
    return {'reservaId': 'mock-new', 'status': 'RESERVADA'};
  }

  @override
  Future<void> cancelReservation({
    required String reservaId,
    required void Function() onSuccess,
    required void Function(String message) onError,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    onSuccess();
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
    await Future.delayed(const Duration(milliseconds: 500));
    onSuccess({'linkPagamento': 'https://mock.link'});
  }
}
