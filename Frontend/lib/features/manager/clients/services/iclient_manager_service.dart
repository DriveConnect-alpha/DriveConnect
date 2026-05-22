import '../../../../core/models/cliente.dart';

abstract class IClientManagerService {
  Future<List<Cliente>> getClients();
}
