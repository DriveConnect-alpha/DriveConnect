import '../../../core/models/usuario.dart';
import 'iauth_service.dart';

class MockAuthService implements IAuthService {
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // Lógica simples de mock para aceitar qualquer login que pareça válido
    if (email.contains('admin') || email.contains('gerente')) {
      return {
        'token': 'mock-token-manager',
        'user': Usuario(
          id: 'm1',
          email: email,
          tipo: 'GERENTE',
        ),
      };
    } else {
      return {
        'token': 'mock-token-client',
        'user': Usuario(
          id: 'c1',
          email: email,
          tipo: 'CLIENTE',
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
}
