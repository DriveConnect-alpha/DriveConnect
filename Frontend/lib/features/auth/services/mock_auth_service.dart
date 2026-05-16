import '../../../core/models/usuario.dart';
import 'iauth_service.dart';

class MockAuthService implements IAuthService {
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email.contains('admin') || email.contains('gerente')) {
      final isActuallyAdmin = email.contains('admin');
      return {
        'token': isActuallyAdmin ? 'mock-token-admin' : 'mock-token-manager',
        'user': Usuario(
          id: isActuallyAdmin ? 'a1' : 'm1',
          nome: isActuallyAdmin ? 'Administrador do Sistema' : 'Gerente da Filial',
          email: email,
          tipo: isActuallyAdmin ? 'ADMIN' : 'GERENTE',
          perfilId: isActuallyAdmin ? null : 'g1',
          filialId: isActuallyAdmin ? null : 'f1',
          imagemUrl: null,
          preferencias: {},
          criadoEm: DateTime.now(),
        ),
      };
    } else {
      return {
        'token': 'mock-token-client',
        'user': Usuario(
          id: 'c1',
          nome: 'Nome do Cliente',
          email: email,
          tipo: 'CLIENTE',
          perfilId: 'c1',
          filialId: null,
          imagemUrl: null,
          preferencias: {},
          criadoEm: DateTime.now(),
        ),
      };
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String nomeCompleto,
    required String cpf,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<Usuario> updateProfile({
    required String id,
    required String nomeCompleto,
    required String email,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return Usuario(
      id: id,
      nome: nomeCompleto,
      email: email,
      tipo: 'CLIENTE',
      perfilId: id,
      filialId: null,
      imagemUrl: null,
      preferencias: {},
      criadoEm: DateTime.now(),
    );
  }

  @override
  Future<void> changePassword({
    required String id,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<String> updateProfilePhoto({
    required String id,
    required dynamic imageFile,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'mock_photo_url.jpg';
  }

  @override
  Future<void> updatePreferences({
    required String id,
    required Map<String, dynamic> preferences,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> deleteAccount(String id) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
