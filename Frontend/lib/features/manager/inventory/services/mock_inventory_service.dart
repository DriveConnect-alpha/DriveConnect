import '../../../../core/models/veiculo.dart';
import '../../../../core/models/modelo.dart';
import 'iinventory_service.dart';

class MockInventoryService implements IInventoryService {
  @override
  Future<List<Veiculo>> getInventory() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Veiculo(
        id: 'v1',
        placa: 'ABC-1234',
        ano: 2023,
        status: 'DISPONIVEL',
        modelo: Modelo(id: 1, nome: 'Corolla', marca: 'Toyota'),
      ),
    ];
  }

  @override
  Future<void> updateVehicleStatus(String id, String status) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> addVehicle(Veiculo veiculo) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
