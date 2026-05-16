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
  Future<void> changePassword({
    required String id,
    required String newPassword,
  });
  Future<String> updateProfilePhoto({
    required String id,
    required dynamic imageFile,
  });
  Future<void> updatePreferences({
    required String id,
    required Map<String, dynamic> preferences,
  });
  Future<void> removeProfilePhoto({required String id});
  Future<void> deleteAccount(String id);
}
