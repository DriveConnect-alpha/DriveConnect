class Usuario {
  final String id;
  final String email;
  final String nome;
  final String tipo; // 'CLIENTE' | 'GERENTE' | 'ADMIN'
  final DateTime criadoEm;

  Usuario({
    required this.id,
    required this.email,
    required this.nome,
    required this.tipo,
    required this.criadoEm,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      email: json['email'],
      nome: json['nome'] ?? 'Usuário',
      tipo: json['tipo'],
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'tipo': tipo,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
