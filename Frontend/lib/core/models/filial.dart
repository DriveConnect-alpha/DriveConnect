class GerenteDaFilial {
  final String id;
  final String nomeCompleto;

  GerenteDaFilial({
    required this.id,
    required this.nomeCompleto,
  });

  factory GerenteDaFilial.fromJson(Map<String, dynamic> json) {
    return GerenteDaFilial(
      id: json['id'] ?? '',
      nomeCompleto: json['nomeCompleto'] ?? '',
    );
  }
}

class Filial {
  final String id;
  final String? nome;
  final String? cep;
  final String? uf;
  final String? cidade;
  final String? bairro;
  final String? rua;
  final String? numero;
  final String? complemento;
  final bool ativo;
  final DateTime? criadoEm;
  final DateTime? deletadoEm;
  final GerenteDaFilial? gerenteResponsavel;

  Filial({
    required this.id,
    this.nome,
    this.cep,
    this.uf,
    this.cidade,
    this.bairro,
    this.rua,
    this.numero,
    this.complemento,
    required this.ativo,
    this.criadoEm,
    this.deletadoEm,
    this.gerenteResponsavel,
  });

  factory Filial.fromJson(Map<String, dynamic> json) {
    try {
      return Filial(
        id: json['id']?.toString() ?? '',
        nome: json['nome']?.toString(),
        cep: json['cep']?.toString(),
        uf: json['uf']?.toString(),
        cidade: json['cidade']?.toString(),
        bairro: json['bairro']?.toString(),
        rua: json['rua']?.toString(),
        numero: json['numero']?.toString(),
        complemento: json['complemento']?.toString(),
        ativo: json['ativo'] ?? true,
        criadoEm: json['criado_em'] != null ? DateTime.tryParse(json['criado_em'].toString()) : null,
        deletadoEm: json['deletado_em'] != null ? DateTime.tryParse(json['deletado_em'].toString()) : null,
        gerenteResponsavel: json['gerenteResponsavel'] != null 
          ? GerenteDaFilial.fromJson(json['gerenteResponsavel'])
          : null,
      );
    } catch (e) {
      print('Error parsing Filial: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cep': cep,
      'uf': uf,
      'cidade': cidade,
      'bairro': bairro,
      'rua': rua,
      'numero': numero,
      'complemento': complemento,
      'ativo': ativo,
      if (criadoEm != null) 'criado_em': criadoEm!.toIso8601String(),
      if (deletadoEm != null) 'deletado_em': deletadoEm!.toIso8601String(),
      if (gerenteResponsavel != null) 'gerenteResponsavel': {
        'id': gerenteResponsavel!.id,
        'nomeCompleto': gerenteResponsavel!.nomeCompleto,
      },
    };
  }
}
