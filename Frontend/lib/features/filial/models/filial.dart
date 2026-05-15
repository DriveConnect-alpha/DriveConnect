class Filial {
  final String id;
  final String nome;
  final String cidade;
  final String uf;

  Filial({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.uf,
  });

  factory Filial.fromJson(Map<String, dynamic> json) {
    return Filial(
      id: json['id'],
      nome: json['nome'] ?? '',
      cidade: json['cidade'] ?? '',
      uf: json['uf'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cidade': cidade,
      'uf': uf,
    };
  }

  @override
  String toString() => '$nome ($cidade - $uf)';
}
