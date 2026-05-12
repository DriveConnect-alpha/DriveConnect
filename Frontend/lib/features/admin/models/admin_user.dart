class AdminUser {
  final String id;
  final String email;
  final String tipo;
  final String criadoEm;
  final String nome;
  final Map<String, dynamic> detalhes;

  AdminUser({
    required this.id,
    required this.email,
    required this.tipo,
    required this.criadoEm,
    required this.nome,
    required this.detalhes,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['id'] ?? json['usuario_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'CLIENTE').toString(),
      criadoEm: (json['criado_em'] ?? json['criadoEm'] ?? '').toString(),
      nome: (json['nome'] ?? json['nome_completo'] ?? json['nomeCompleto'] ?? 'Usuário sem nome').toString(),
      detalhes: json, // Pass the whole map as details for flexibility
    );
  }
}
