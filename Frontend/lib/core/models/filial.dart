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
  });

  factory Filial.fromJson(Map<String, dynamic> json) {
    return Filial(
      id: json['id'],
      nome: json['nome'],
      cep: json['cep'],
      uf: json['uf'],
      cidade: json['cidade'],
      bairro: json['bairro'],
      rua: json['rua'],
      numero: json['numero'],
      complemento: json['complemento'],
      ativo: json['ativo'] ?? true,
    );
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
    };
  }
}
