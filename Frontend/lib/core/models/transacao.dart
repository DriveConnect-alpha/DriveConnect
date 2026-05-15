class Transacao {
  final String id;
  final String? filialId; // NULL = corporativa
  final String tipo; // 'ENTRADA' | 'SAIDA'
  final double? valor;
  final String? descricao;
  final DateTime criadoEm;

  Transacao({
    required this.id,
    this.filialId,
    required this.tipo,
    this.valor,
    this.descricao,
    required this.criadoEm,
  });

  factory Transacao.fromJson(Map<String, dynamic> json) {
    return Transacao(
      id: json['id'],
      filialId: json['filial_id'],
      tipo: json['tipo'],
      valor: json['valor'] != null ? (json['valor'] as num).toDouble() : null,
      descricao: json['descricao'],
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filial_id': filialId,
      'tipo': tipo,
      'valor': valor,
      'descricao': descricao,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
