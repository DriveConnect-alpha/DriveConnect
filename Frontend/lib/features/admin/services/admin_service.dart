import '../../../core/network/api_client.dart';
import '../models/admin_user.dart';
import 'iadmin_service.dart';

class AdminService implements IAdminService {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  @override
  Future<List<AdminUser>> listUsers() async {
    final response = await _apiClient.get('/usuarios');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => AdminUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  @override
  Future<void> updateUser(String id, {String? nome, String? email, String? novaSenha}) async {
    final body = <String, dynamic>{};
    if (nome != null) body['nome'] = nome;
    if (email != null) body['email'] = email;
    if (novaSenha != null) body['novaSenha'] = novaSenha;

    final response = await _apiClient.put('/usuarios/$id', data: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
  }

  @override
  Future<void> registerManager({
    required String email,
    required String password,
    required String nomeCompleto,
    required String filialId,
  }) async {
    final response = await _apiClient.post(
      '/auth/register-manager',
      data: {
        'email': email,
        'password': password,
        'nome_completo': nomeCompleto,
        'filial_id': filialId,
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to register manager: ${response.data['erro'] ?? 'Unknown error'}');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    final response = await _apiClient.delete('/usuarios/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to deactivate user');
    }
  }
}
