import 'dart:async';
import '../models/filial.dart';
import '../../../calls/filial.call.dart';
import 'ifilial_service.dart';

class FilialService implements IFilialService {
  @override
  Future<List<Filial>> listFiliais() async {
    final completer = Completer<List<Filial>>();

    await FilialCall.listar(
      onSuccess: (data) {
        final filiais = data.map((json) => Filial.fromJson(json)).toList();
        completer.complete(filiais);
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
