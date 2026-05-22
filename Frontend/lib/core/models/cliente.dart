import 'usuario.dart';

class Cliente {
  final String id;
  final String usuarioId;
  final String nomeCompleto;
  final String cpf;
  final String? rg;
  final String? cnh;
  final String? telefone;
  final DateTime criadoEm;
  final DateTime? deletadoEm;

  // Campos de JOIN
  final Usuario? usuario;

  Cliente({
    required this.id,
    required this.usuarioId,
    required this.nomeCompleto,
    required this.cpf,
    this.rg,
    this.cnh,
    this.telefone,
    required this.criadoEm,
    this.deletadoEm,
    this.usuario,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      usuarioId: json['usuario_id'],
      nomeCompleto: json['nome_completo'],
      cpf: json['cpf'],
      rg: json['rg'],
      cnh: json['cnh'],
      telefone: json['telefone'],
      criadoEm: DateTime.parse(json['criado_em']),
      deletadoEm: json['deletado_em'] != null ? DateTime.parse(json['deletado_em']) : null,
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome_completo': nomeCompleto,
      'cpf': cpf,
      'rg': rg,
      'cnh': cnh,
      'telefone': telefone,
      'criado_em': criadoEm.toIso8601String(),
      'deletado_em': deletadoEm?.toIso8601String(),
    };
  }
}
