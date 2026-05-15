import '../../../core/models/usuario.dart';

abstract class IAuthService {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<void> register({
    required String email,
    required String password,
    required String nomeCompleto,
    required String cpf,
  });
  Future<Usuario> updateProfile({
    required String id,
    required String nomeCompleto,
    required String email,
  });
  Future<void> deleteAccount(String id);
}
