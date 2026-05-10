import '../../../../core/network/api_client.dart';
import '../../../../core/models/plano_seguro.dart';
import 'iinsurance_service.dart';

class InsuranceService implements IInsuranceService {
  final ApiClient _apiClient;

  InsuranceService(this._apiClient);

  @override
  Future<List<PlanoSeguro>> getPlanos() async {
    final response = await _apiClient.get('/planos-seguro');
    return (response.data as List).map((p) => PlanoSeguro.fromJson(p)).toList();
  }

  @override
  Future<void> updatePlano(String id, Map<String, dynamic> data) async {
    await _apiClient.put('/planos-seguro/$id', data: data);
  }
}
