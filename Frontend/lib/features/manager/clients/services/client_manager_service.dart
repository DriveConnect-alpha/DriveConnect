import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/models/cliente.dart';
import '../../../../calls/gerente.call.dart';
import 'iclient_manager_service.dart';

class ClientManagerService implements IClientManagerService {
  @override
  Future<List<Cliente>> getClients() async {
    final completer = Completer<List<Cliente>>();

    await GerenteCall.listarClientes(
      onSuccess: (data) {
        try {
          final clientes = data.map((c) => Cliente.fromJson(c)).toList();
          completer.complete(clientes);
        } catch (e, stack) {
          debugPrint('ERRO NO MAPPING DE CLIENTE: $e');
          debugPrint(stack.toString());
          completer.completeError(Exception('Erro ao processar dados dos clientes: $e'));
        }
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
