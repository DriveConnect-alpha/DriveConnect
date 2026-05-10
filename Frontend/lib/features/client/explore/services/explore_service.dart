import '../../../../core/network/api_client.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/network/api_exceptions.dart';

class ExploreService {
  final ApiClient _apiClient;

  ExploreService(this._apiClient);

  Future<List<Veiculo>> listarVeiculos({String? tipo, String? busca}) async {
    try {
      final response = await _apiClient.dio.get(
        '/veiculos',
        queryParameters: {
          if (tipo != null) 'tipo': tipo,
          if (busca != null) 'busca': busca,
        },
      );
      return (response.data as List)
          .map((item) => Veiculo.fromJson(item))
          .toList();
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
