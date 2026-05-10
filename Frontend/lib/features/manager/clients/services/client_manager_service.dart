import '../../../../core/network/api_client.dart';
import '../../../../core/models/cliente.dart';
import 'iclient_manager_service.dart';

class ClientManagerService implements IClientManagerService {
  final ApiClient _apiClient;

  ClientManagerService(this._apiClient);

  @override
  Future<List<Cliente>> getClients() async {
    final response = await _apiClient.get('/clientes');
    return (response.data as List).map((c) => Cliente.fromJson(c)).toList();
  }
}
