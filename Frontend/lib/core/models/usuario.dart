class Usuario {
  final String id;
  final String email;
  final String nome;
  final String tipo; // 'CLIENTE' | 'GERENTE' | 'ADMIN'
  final String? perfilId;
  final DateTime criadoEm;

  Usuario({
    required this.id,
    required this.email,
    required this.nome,
    required this.tipo,
    this.perfilId,
    required this.criadoEm,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      email: json['email'],
      nome: json['nome'] ?? 'Usuário',
      tipo: json['tipo'],
      perfilId: json['perfilId'],
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'tipo': tipo,
      'perfilId': perfilId,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
