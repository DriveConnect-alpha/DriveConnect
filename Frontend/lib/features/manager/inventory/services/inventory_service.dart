import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../calls/frota.call.dart';
import 'iinventory_service.dart';

class InventoryService implements IInventoryService {
  @override
  Future<List<Veiculo>> getInventory() async {
    final completer = Completer<List<Veiculo>>();

    await FrotaCall.listarVeiculos(
      onSuccess: (data) {
        final veiculos = data.map((v) => Veiculo.fromJson(v)).toList();
        completer.complete(veiculos);
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> updateVehicleStatus(String id, String status) async {
    final completer = Completer<void>();

    await FrotaCall.atualizarVeiculo(
      id: id,
      status: status,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> addVehicle(Veiculo veiculo, {List<XFile>? images, double? precoDiaria, List<String>? itensIds}) async {
    final completer = Completer<void>();

    await FrotaCall.registrarVeiculo(
      modeloId: veiculo.modeloId ?? 0,
      filialId: veiculo.filialId ?? '',
      placa: veiculo.placa,
      ano: veiculo.ano,
      cor: veiculo.cor ?? 'Não especificada',
      status: veiculo.status,
      imagens: images,
      precoDiaria: precoDiaria,
      itensIds: itensIds,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }

  @override
  Future<void> updateVehicle(String id, {int? modeloId, String? filialId, String? placa, int? ano, String? cor, String? status}) async {
    final completer = Completer<void>();

    await FrotaCall.atualizarVeiculo(
      id: id,
      modeloId: modeloId,
      filialId: filialId,
      placa: placa,
      ano: ano,
      cor: cor,
      status: status,
      onSuccess: (_) => completer.complete(),
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
