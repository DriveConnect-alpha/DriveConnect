import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/usuario.dart';
import '../../../core/network/api_exceptions.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'senha': password,
        },
      );

      return {
        'token': response.data['token'],
        'user': Usuario.fromJson(response.data['user']),
      };
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nomeCompleto,
    required String cpf,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'senha': password,
          'nome_completo': nomeCompleto,
          'cpf': cpf,
        },
      );
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
