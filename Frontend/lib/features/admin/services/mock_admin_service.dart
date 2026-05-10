import '../models/admin_user.dart';
import 'iadmin_service.dart';

class MockAdminService implements IAdminService {
  final List<AdminUser> _users = [
    AdminUser(
      id: '1',
      email: 'admin@driveconnect.com',
      tipo: 'ADMIN',
      criadoEm: DateTime.now().toIso8601String(),
      nome: 'Administrador Supremo',
      detalhes: {},
    ),
    AdminUser(
      id: '2',
      email: 'gerente@driveconnect.com',
      tipo: 'GERENTE',
      criadoEm: DateTime.now().toIso8601String(),
      nome: 'Gerente Principal',
      detalhes: {'filial_id': 'f1'},
    ),
    AdminUser(
      id: '3',
      email: 'cliente@exemplo.com',
      tipo: 'CLIENTE',
      criadoEm: DateTime.now().toIso8601String(),
      nome: 'Cliente Fiel',
      detalhes: {'cpf': '111.222.333-44'},
    ),
  ];

  @override
  Future<List<AdminUser>> listUsers() async {
    await Future.delayed(const Duration(seconds: 1));
    return _users;
  }

  @override
  Future<void> updateUser(String id, {String? nome, String? email, String? novaSenha}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) throw Exception('Usuário não encontrado');
    
    final oldUser = _users[index];
    _users[index] = AdminUser(
      id: oldUser.id,
      email: email ?? oldUser.email,
      tipo: oldUser.tipo,
      criadoEm: oldUser.criadoEm,
      nome: nome ?? oldUser.nome,
      detalhes: oldUser.detalhes,
    );
  }

  @override
  Future<void> registerManager({
    required String email,
    required String password,
    required String nomeCompleto,
    required String filialId,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _users.add(AdminUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      tipo: 'GERENTE',
      criadoEm: DateTime.now().toIso8601String(),
      nome: nomeCompleto,
      detalhes: {'filial_id': filialId},
    ));
  }

  @override
  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _users.removeWhere((u) => u.id == id);
  }
}
