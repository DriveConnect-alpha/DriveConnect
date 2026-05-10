class ApiConstants {
  static const String baseUrl = 'http://localhost:3000'; // Alterar conforme necessário

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
