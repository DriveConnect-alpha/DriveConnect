class GerenteDaFilial {
  final String id;
  final String nomeCompleto;

  GerenteDaFilial({
    required this.id,
    required this.nomeCompleto,
  });

  factory GerenteDaFilial.fromJson(Map<String, dynamic> json) {
    return GerenteDaFilial(
      id: json['id'],
      nomeCompleto: json['nomeCompleto'] ?? '',
    );
  }
}

class Filial {
  final String id;
  final String nome;
  final String cidade;
  final String uf;
  final GerenteDaFilial? gerenteResponsavel;

  Filial({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.uf,
    this.gerenteResponsavel,
  });

  factory Filial.fromJson(Map<String, dynamic> json) {
    return Filial(
      id: json['id'],
      nome: json['nome'] ?? '',
      cidade: json['cidade'] ?? '',
      uf: json['uf'] ?? '',
      gerenteResponsavel: json['gerenteResponsavel'] != null 
        ? GerenteDaFilial.fromJson(json['gerenteResponsavel'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cidade': cidade,
      'uf': uf,
      'gerenteResponsavel': gerenteResponsavel != null ? {
        'id': gerenteResponsavel!.id,
        'nomeCompleto': gerenteResponsavel!.nomeCompleto,
      } : null,
    };
  }

  @override
  String toString() => '$nome ($cidade - $uf)';
}
