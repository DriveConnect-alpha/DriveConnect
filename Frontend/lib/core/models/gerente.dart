class Gerente {
  final String id;
  final String usuarioId;
  final String nomeCompleto;
  final String? filialId; // NULL = gerente global
  final DateTime criadoEm;

  Gerente({
    required this.id,
    required this.usuarioId,
    required this.nomeCompleto,
    this.filialId,
    required this.criadoEm,
  });

  factory Gerente.fromJson(Map<String, dynamic> json) {
    return Gerente(
      id: json['id'],
      usuarioId: json['usuario_id'],
      nomeCompleto: json['nome_completo'],
      filialId: json['filial_id'],
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome_completo': nomeCompleto,
      'filial_id': filialId,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
