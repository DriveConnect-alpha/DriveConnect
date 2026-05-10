import '../../../core/network/api_client.dart';
import '../models/filial.dart';
import 'ifilial_service.dart';

class FilialService implements IFilialService {
  final ApiClient _apiClient;

  FilialService(this._apiClient);

  @override
  Future<List<Filial>> listFiliais() async {
    final response = await _apiClient.get('/filiais');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Filial.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar filiais');
    }
  }
}
