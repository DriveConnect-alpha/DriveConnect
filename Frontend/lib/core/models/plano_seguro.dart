class PlanoSeguro {
  final String id;
  final String nome; // ex: "Básico", "Standard", "Premium"
  final String? descricao;
  final double percentual; // 0.00 a 100.00
  final bool obrigatorio; // true = plano básico (sempre incluso)
  final bool ativo;

  double get precoDiaria => percentual; // Alias ou lógica específica se necessário

  PlanoSeguro({
    required this.id,
    required this.nome,
    this.descricao,
    required this.percentual,
    required this.obrigatorio,
    required this.ativo,
  });

  factory PlanoSeguro.fromJson(Map<String, dynamic> json) {
    return PlanoSeguro(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      percentual: (json['percentual'] as num).toDouble(),
      obrigatorio: json['obrigatorio'] ?? false,
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'percentual': percentual,
      'obrigatorio': obrigatorio,
      'ativo': ativo,
    };
  }
}
