import '../../../../core/models/veiculo.dart';
import '../../../../core/models/modelo.dart';
import '../../../../core/models/tipo_carro.dart';
import 'iexplore_service.dart';

class MockExploreService implements IExploreService {
  @override
  Future<List<Veiculo>> getAvailableVehicles() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Veiculo(
        id: 'v1',
        placa: 'ABC-1234',
        ano: 2023,
        status: 'DISPONIVEL',
        criadoEm: DateTime.now(),
        modelo: Modelo(
          id: 1,
          nome: 'Corolla',
          marca: 'Toyota',
          tipoCarro: TipoCarro(id: 1, nome: 'Sedan', precoBaseDiaria: 200),
        ),
      ),
      Veiculo(
        id: 'v2',
        placa: 'XYZ-5678',
        ano: 2022,
        status: 'DISPONIVEL',
        criadoEm: DateTime.now(),
        modelo: Modelo(
          id: 2,
          nome: 'Compass',
          marca: 'Jeep',
          tipoCarro: TipoCarro(id: 2, nome: 'SUV', precoBaseDiaria: 350),
        ),
      ),
    ];
  }
}
