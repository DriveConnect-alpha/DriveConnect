import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/usuario.dart';
import '../../../core/network/api_exceptions.dart';
import 'iauth_service.dart';

class AuthService implements IAuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  @override
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

  @override
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

  @override
  Future<Usuario> updateProfile({
    required String id,
    required String nomeCompleto,
    required String email,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/usuarios/$id',
        data: {
          'nome_completo': nomeCompleto,
          'email': email,
        },
      );
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await _apiClient.dio.delete('/usuarios/$id');
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
