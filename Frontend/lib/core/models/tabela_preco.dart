class TabelaPreco {
  final int id;
  final int? tipoCarroId;
  final String? filialId;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final double valorDiaria;

  TabelaPreco({
    required this.id,
    this.tipoCarroId,
    this.filialId,
    this.dataInicio,
    this.dataFim,
    required this.valorDiaria,
  });

  factory TabelaPreco.fromJson(Map<String, dynamic> json) {
    return TabelaPreco(
      id: json['id'],
      tipoCarroId: json['tipo_carro_id'],
      filialId: json['filial_id'],
      dataInicio: json['data_inicio'] != null ? DateTime.parse(json['data_inicio']) : null,
      dataFim: json['data_fim'] != null ? DateTime.parse(json['data_fim']) : null,
      valorDiaria: (json['valor_diaria'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo_carro_id': tipoCarroId,
      'filial_id': filialId,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'valor_diaria': valorDiaria,
    };
  }
}
