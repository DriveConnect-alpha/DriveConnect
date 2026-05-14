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
  final double? precoDiaria;
  final DateTime criadoEm;
  final DateTime? deletadoEm;

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
    this.precoDiaria,
    required this.criadoEm,
    this.deletadoEm,
    this.modelo,
    this.filial,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) {
    try {
      return Veiculo(
        id: json['id']?.toString() ?? '',
        modeloId: json['modelo_id'] != null ? int.tryParse(json['modelo_id'].toString()) : null,
        filialId: json['filial_id']?.toString(),
        placa: json['placa']?.toString() ?? '',
        ano: json['ano'] != null ? int.tryParse(json['ano'].toString()) ?? 0 : 0,
        cor: json['cor']?.toString(),
        status: json['status']?.toString() ?? 'DISPONIVEL',
        imagemUrl: json['imagem_url']?.toString(),
        precoDiaria: json['preco_diaria'] != null ? double.tryParse(json['preco_diaria'].toString()) : null,
        criadoEm: json['criado_em'] != null ? DateTime.tryParse(json['criado_em'].toString()) ?? DateTime.now() : DateTime.now(),
        deletadoEm: json['deletado_em'] != null ? DateTime.tryParse(json['deletado_em'].toString()) : null,
        modelo: json['modelo'] != null ? Modelo.fromJson(json['modelo']) : null,
        filial: json['filial'] != null ? Filial.fromJson(json['filial']) : null,
      );
    } catch (e) {
      print('Error parsing Veiculo: $e');
      print('JSON data: $json');
      rethrow;
    }
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
      'preco_diaria': precoDiaria,
      'criado_em': criadoEm.toIso8601String(),
      'deletado_em': deletadoEm?.toIso8601String(),
    };
  }
}
