import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Reservas
  static const String disponibilidade = '/reservas/disponibilidade';
  static const String retirada = '/reservas/{id}/retirada';
  static const String devolucao = '/reservas/{id}/devolucao';

  // Pagamento
  static const String iniciarPagamento = '/pagamento/iniciar';
  static const String statusPagamento = '/pagamento/status/{reservaId}';

  // Seguros
  static const String seguros = '/seguros';
}
