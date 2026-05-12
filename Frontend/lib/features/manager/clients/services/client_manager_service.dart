import 'dart:async';
import '../../../../core/models/cliente.dart';
import '../../../../calls/gerente.call.dart';
import 'iclient_manager_service.dart';

class ClientManagerService implements IClientManagerService {
  @override
  Future<List<Cliente>> getClients() async {
    final completer = Completer<List<Cliente>>();

    await GerenteCall.listarClientes(
      onSuccess: (data) {
        final clientes = data.map((c) => Cliente.fromJson(c)).toList();
        completer.complete(clientes);
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
