import 'package:image_picker/image_picker.dart';
import '../../../../core/models/veiculo.dart';

abstract class IInventoryService {
  Future<List<Veiculo>> getInventory();
  Future<void> updateVehicleStatus(String id, String status);
  Future<void> addVehicle(Veiculo veiculo, {List<XFile>? images, double? precoDiaria, List<String>? itensIds});
  Future<void> updateVehicle(String id, {int? modeloId, String? filialId, String? placa, int? ano, String? cor, String? status});
}
