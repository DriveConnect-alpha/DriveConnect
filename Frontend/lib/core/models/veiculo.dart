import 'modelo.dart';
import 'filial.dart';

class Veiculo {
  final String id;
  final int? modeloId;
  final String? filialId;
  final String placa;
  final int ano;
  final String? cor;
  final String status; // 'DISPONIVEL' | 'ALUGADO' | 'MANUTENCAO'
  final String? imagemUrl;
  final String? capaUrl;

  // Campos JOIN
  final Modelo? modelo;
  final Filial? filial;

  Veiculo({
    required this.id,
    this.modeloId,
    this.filialId,
    required this.placa,
    required this.ano,
    this.cor,
    required this.status,
    this.imagemUrl,
    this.capaUrl,
    this.modelo,
    this.filial,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) {
    return Veiculo(
      id: json['id'],
      modeloId: json['modelo_id'],
      filialId: json['filial_id'],
      placa: json['placa'],
      ano: json['ano'],
      cor: json['cor'],
      status: json['status'],
      imagemUrl: json['imagem_url'],
      capaUrl: json['capa_url'],
      modelo: json['modelo'] != null ? Modelo.fromJson(json['modelo']) : null,
      filial: json['filial'] != null ? Filial.fromJson(json['filial']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modelo_id': modeloId,
      'filial_id': filialId,
      'placa': placa,
      'ano': ano,
      'cor': cor,
      'status': status,
      'imagem_url': imagemUrl,
    };
  }
}
