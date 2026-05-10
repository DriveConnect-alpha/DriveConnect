import 'tipo_carro.dart';

class Modelo {
  final int id;
  final String nome; // ex: "Corolla", "Civic"
  final String? marca; // ex: "Toyota", "Honda"
  final int? tipoCarroId;
  final TipoCarro? tipoCarro;

  Modelo({
    required this.id,
    required this.nome,
    this.marca,
    this.tipoCarroId,
    this.tipoCarro,
  });

  factory Modelo.fromJson(Map<String, dynamic> json) {
    return Modelo(
      id: json['id'],
      nome: json['nome'],
      marca: json['marca'],
      tipoCarroId: json['tipo_carro_id'],
      tipoCarro: json['tipo_carro'] != null
          ? TipoCarro.fromJson(json['tipo_carro'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'marca': marca,
      'tipo_carro_id': tipoCarroId,
    };
  }
}
