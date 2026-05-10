import '../../../../core/models/cliente.dart';
import 'iclient_manager_service.dart';

class MockClientManagerService implements IClientManagerService {
  @override
  Future<List<Cliente>> getClients() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Cliente(id: 'c1', nomeCompleto: 'João Silva', cpf: '123.456.789-00', telefone: '(11) 99999-9999', email: 'joao@example.com'),
      Cliente(id: 'c2', nomeCompleto: 'Maria Souza', cpf: '987.654.321-11', telefone: '(11) 88888-8888', email: 'maria@example.com'),
    ];
  }
}
