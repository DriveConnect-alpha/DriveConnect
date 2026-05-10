import '../../../../core/network/api_client.dart';
import '../../../../core/models/veiculo.dart';
import 'iexplore_service.dart';

class ExploreService implements IExploreService {
  final ApiClient _apiClient;

  ExploreService(this._apiClient);

  @override
  Future<List<Veiculo>> getAvailableVehicles() async {
    final response = await _apiClient.dio.get('/veiculos');
    return (response.data as List).map((item) => Veiculo.fromJson(item)).toList();
  }
}
