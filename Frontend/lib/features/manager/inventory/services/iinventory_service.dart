import '../../../../core/models/veiculo.dart';

abstract class IInventoryService {
  Future<List<Veiculo>> getInventory();
  Future<void> updateVehicleStatus(String id, String status);
}
