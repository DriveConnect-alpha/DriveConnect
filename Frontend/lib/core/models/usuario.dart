class Usuario {
  final String id;
  final String email;
  final String tipo; // 'CLIENTE' | 'GERENTE' | 'ADMIN'
  final DateTime criadoEm;

  Usuario({
    required this.id,
    required this.email,
    required this.tipo,
    required this.criadoEm,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      email: json['email'],
      tipo: json['tipo'],
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'tipo': tipo,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
