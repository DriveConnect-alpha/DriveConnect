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
    try {
      return TipoCarro(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
        nome: json['nome']?.toString() ?? '',
        precoBaseDiaria: json['preco_base_diaria'] != null ? double.tryParse(json['preco_base_diaria'].toString()) ?? 0.0 : 0.0,
      );
    } catch (e) {
      print('Error parsing TipoCarro: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'preco_base_diaria': precoBaseDiaria,
    };
  }
}
