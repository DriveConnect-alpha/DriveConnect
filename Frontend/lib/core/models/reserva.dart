import 'package:flutter/foundation.dart';
import 'veiculo.dart';
import 'cliente.dart';

class Reserva {
  final String id;
  final String? clienteId;
  final String? veiculoId;
  final String? filialRetiradaId;
  final String? filialDevolucaoId;
  final DateTime dataInicio;
  final DateTime dataFim;
  final DateTime? dataRetiradaReal;
  final DateTime? dataDevolucaoReal;
  final double? valorTotal;
  final double? valorAdicional;
  final String status;
  // Status: 'PENDENTE_PAGAMENTO' | 'RESERVADA' | 'ATIVA' | 'FINALIZADA' | 'CANCELADA' | 'EXPIRADA'

  // Pagamento InfinitePay
  final String? infinitepayOrderNsu;
  final String? infinitepaySlug;
  final String? infinitepayNsu;
  final String? metodoPagamento; // "credit_card" | "pix"
  final String? linkPagamento;
  final String? comprovanteUrl;
  final DateTime? pagamentoEm;
  final DateTime? expiraEm;

  // Seguro
  final String? planoSeguroId;
  final double? valorSeguro;

  // Campos de JOIN
  final Veiculo? veiculo;
  final Cliente? cliente;

  Reserva({
    required this.id,
    this.clienteId,
    this.veiculoId,
    this.filialRetiradaId,
    this.filialDevolucaoId,
    required this.dataInicio,
    required this.dataFim,
    this.dataRetiradaReal,
    this.dataDevolucaoReal,
    this.valorTotal,
    this.valorAdicional,
    required this.status,
    this.infinitepayOrderNsu,
    this.infinitepaySlug,
    this.infinitepayNsu,
    this.metodoPagamento,
    this.linkPagamento,
    this.comprovanteUrl,
    this.pagamentoEm,
    this.expiraEm,
    this.planoSeguroId,
    this.valorSeguro,
    this.veiculo,
    this.cliente,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory Reserva.fromJson(Map<String, dynamic> json) {
    try {
      return Reserva(
        id: json['id'] ?? '',
        clienteId: json['cliente_id'],
        veiculoId: json['veiculo_id'],
        filialRetiradaId: json['filial_retirada_id'],
        filialDevolucaoId: json['filial_devolucao_id'],
        dataInicio: json['data_inicio'] != null ? DateTime.parse(json['data_inicio']) : DateTime.now(),
        dataFim: json['data_fim'] != null ? DateTime.parse(json['data_fim']) : DateTime.now(),
        dataRetiradaReal: json['data_retirada_real'] != null
            ? DateTime.parse(json['data_retirada_real'])
            : null,
        dataDevolucaoReal: json['data_devolucao_real'] != null
            ? DateTime.parse(json['data_devolucao_real'])
            : null,
        valorTotal: _toDouble(json['valor_total']),
        valorAdicional: _toDouble(json['valor_adicional']),
        status: json['status'] ?? 'DESCONHECIDO',
        infinitepayOrderNsu: json['infinitepay_order_nsu'],
        infinitepaySlug: json['infinitepay_slug'],
        infinitepayNsu: json['infinitepay_nsu'],
        metodoPagamento: json['metodo_pagamento'],
        linkPagamento: json['link_pagamento'],
        comprovanteUrl: json['comprovante_url'],
        pagamentoEm: json['pagamento_em'] != null
            ? DateTime.parse(json['pagamento_em'])
            : null,
        expiraEm: json['expira_em'] != null
            ? DateTime.parse(json['expira_em'])
            : null,
        planoSeguroId: json['plano_seguro_id'],
        valorSeguro: _toDouble(json['valor_seguro']),
        veiculo: _parseVeiculo(json['veiculo']),
        cliente: _parseCliente(json['cliente']),
      );
    } catch (e) {
      debugPrint('Erro ao parsear Reserva: $e');
      // Retorna uma reserva "dummy" com erro para evitar crash total se necessário, 
      // ou apenas propaga o erro para ser capturado no provider.
      rethrow;
    }
  }

  static Veiculo? _parseVeiculo(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) return null;
    try {
      return Veiculo.fromJson(json);
    } catch (e) {
      debugPrint('Erro ao parsear Veiculo na Reserva: $e');
      return null;
    }
  }

  static Cliente? _parseCliente(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) return null;
    try {
      return Cliente.fromJson(json);
    } catch (e) {
      debugPrint('Erro ao parsear Cliente na Reserva: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'veiculo_id': veiculoId,
      'filial_retirada_id': filialRetiradaId,
      'filial_devolucao_id': filialDevolucaoId,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
      'data_retirada_real': dataRetiradaReal?.toIso8601String(),
      'data_devolucao_real': dataDevolucaoReal?.toIso8601String(),
      'valor_total': valorTotal,
      'valor_adicional': valorAdicional,
      'status': status,
      'infinitepay_order_nsu': infinitepayOrderNsu,
      'infinitepay_slug': infinitepaySlug,
      'infinitepay_nsu': infinitepayNsu,
      'metodo_pagamento': metodoPagamento,
      'link_pagamento': linkPagamento,
      'comprovante_url': comprovanteUrl,
      'pagamento_em': pagamentoEm?.toIso8601String(),
      'expira_em': expiraEm?.toIso8601String(),
      'plano_seguro_id': planoSeguroId,
      'valor_seguro': valorSeguro,
    };
  }
}

