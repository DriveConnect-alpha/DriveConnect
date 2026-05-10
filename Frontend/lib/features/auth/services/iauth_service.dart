import '../../../core/models/usuario.dart';

abstract class IAuthService {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<void> register({
    required String email,
    required String password,
    required String nomeCompleto,
    required String cpf,
  });
}
