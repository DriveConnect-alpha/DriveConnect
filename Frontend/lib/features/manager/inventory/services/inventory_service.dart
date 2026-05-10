import '../../../../core/network/api_client.dart';
import '../../../../core/models/veiculo.dart';
import 'iinventory_service.dart';

class InventoryService implements IInventoryService {
  final ApiClient _apiClient;

  InventoryService(this._apiClient);

  @override
  Future<List<Veiculo>> getInventory() async {
    final response = await _apiClient.get('/veiculos');
    return (response.data as List).map((v) => Veiculo.fromJson(v)).toList();
  }

  @override
  Future<void> updateVehicleStatus(String id, String status) async {
    await _apiClient.patch('/veiculos/$id/status', data: {'status': status});
  }
}
