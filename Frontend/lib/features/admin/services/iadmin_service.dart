import '../models/admin_user.dart';

abstract class IAdminService {
  Future<List<AdminUser>> listUsers();
  Future<void> updateUser(String id, {String? nome, String? email, String? novaSenha});
  Future<void> registerManager({
    required String email,
    required String password,
    required String nomeCompleto,
    required String filialId,
  });
  Future<void> deleteUser(String id);
}
