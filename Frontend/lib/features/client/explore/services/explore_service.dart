import 'dart:async';
import '../../../../core/models/veiculo.dart';
import '../../../../calls/frota.call.dart';
import 'iexplore_service.dart';

class ExploreService implements IExploreService {
  @override
  Future<List<Veiculo>> getAvailableVehicles() async {
    final completer = Completer<List<Veiculo>>();

    await FrotaCall.listarVeiculos(
      onSuccess: (data) {
        final veiculos = data.map((item) => Veiculo.fromJson(item)).toList();
        completer.complete(veiculos);
      },
      onError: (msg) {
        completer.completeError(Exception(msg));
      },
    );

    return completer.future;
  }
}
