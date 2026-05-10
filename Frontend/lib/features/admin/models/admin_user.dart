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
      id: json['id'] as String,
      email: json['email'] as String,
      tipo: json['tipo'] as String,
      criadoEm: json['criado_em'] as String,
      nome: json['nome'] as String,
      detalhes: json['detalhes'] as Map<String, dynamic>? ?? {},
    );
  }
}
