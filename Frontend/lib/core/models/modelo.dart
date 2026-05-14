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
    try {
      return Modelo(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
        nome: json['nome']?.toString() ?? '',
        marca: json['marca']?.toString(),
        tipoCarroId: json['tipo_carro_id'] != null ? int.tryParse(json['tipo_carro_id'].toString()) : null,
        tipoCarro: Modelo._tipoCarroFromJson(json),
      );
    } catch (e) {
      print('Error parsing Modelo: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  /// Aceita `tipo_carro` (API de modelos / veículos) ou `tipo` (legado).
  static TipoCarro? _tipoCarroFromJson(Map<String, dynamic> json) {
    final raw = json['tipo_carro'] ?? json['tipo'];
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return TipoCarro.fromJson(raw);
    return null;
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
