import 'dart:async';
import '../../../../core/models/plano_seguro.dart';
import '../../../../calls/seguro.call.dart';
import 'iinsurance_service.dart';

class InsuranceService implements IInsuranceService {
  @override
  Future<List<PlanoSeguro>> getPlanos() async {
    final completer = Completer<List<PlanoSeguro>>();

    await SeguroCall.listar(
      onSuccess: (data) {
        final planos = data.map((p) => PlanoSeguro.fromJson(p)).toList();
        completer.complete(planos);
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> updatePlano(String id, Map<String, dynamic> data) async {
    final completer = Completer<void>();

    await SeguroCall.atualizar(
      planoId: id,
      nome: data['nome'] as String?,
      descricao: data['descricao'] as String?,
      percentual: data['percentual'] as double?,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
