import '../../../../core/models/cliente.dart';
import 'iclient_manager_service.dart';

class MockClientManagerService implements IClientManagerService {
  @override
  Future<List<Cliente>> getClients() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Cliente(
        id: 'c1',
        nomeCompleto: 'João Silva',
        cpf: '123.456.789-00',
        usuarioId: 'u1',
        criadoEm: DateTime.now(),
      ),
      Cliente(
        id: 'c2',
        nomeCompleto: 'Maria Souza',
        cpf: '987.654.321-11',
        usuarioId: 'u2',
        criadoEm: DateTime.now(),
      ),
    ];
  }
}
