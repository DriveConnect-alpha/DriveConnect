class TipoCarro {
  final int id;
  final String nome; // ex: "SUV", "Sedan", "Hatch"
  final double precoBaseDiaria;

  TipoCarro({
    required this.id,
    required this.nome,
    required this.precoBaseDiaria,
  });

  factory TipoCarro.fromJson(Map<String, dynamic> json) {
    return TipoCarro(
      id: json['id'],
      nome: json['nome'],
      precoBaseDiaria: (json['preco_base_diaria'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'preco_base_diaria': precoBaseDiaria,
    };
  }
}
