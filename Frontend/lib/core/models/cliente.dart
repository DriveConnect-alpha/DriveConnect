class Cliente {
  final String id;
  final String usuarioId;
  final String nomeCompleto;
  final String cpf;
  final String? rg;
  final String? cnh;
  final DateTime criadoEm;

  Cliente({
    required this.id,
    required this.usuarioId,
    required this.nomeCompleto,
    required this.cpf,
    this.rg,
    this.cnh,
    required this.criadoEm,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      usuarioId: json['usuario_id'],
      nomeCompleto: json['nome_completo'],
      cpf: json['cpf'],
      rg: json['rg'],
      cnh: json['cnh'],
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome_completo': nomeCompleto,
      'cpf': cpf,
      'rg': rg,
      'cnh': cnh,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
