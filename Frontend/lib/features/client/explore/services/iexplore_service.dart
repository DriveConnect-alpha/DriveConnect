import '../../../../core/models/veiculo.dart';

abstract class IExploreService {
  Future<List<Veiculo>> getAvailableVehicles();
}
