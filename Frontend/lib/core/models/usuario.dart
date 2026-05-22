class Usuario {
  final String id;
  final String email;
  final String nome;
  final String tipo; // 'CLIENTE' | 'GERENTE' | 'ADMIN'
  final String? perfilId;
  /// Filial do gerente (null para cliente, admin ou gerente global).
  final String? filialId;
  final String? imagemUrl;
  final Map<String, dynamic> preferencias;
  final DateTime criadoEm;

  Usuario({
    required this.id,
    required this.email,
    required this.nome,
    required this.tipo,
    this.perfilId,
    this.filialId,
    this.imagemUrl,
    this.preferencias = const {},
    required this.criadoEm,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      email: json['email'] as String,
      nome: json['nome'] as String? ?? 'Usuário',
      tipo: json['tipo'] as String,
      perfilId: json['perfilId'] as String? ?? json['perfil_id'] as String?,
      filialId: json['filialId'] as String? ?? json['filial_id'] as String?,
      imagemUrl: json['imagemUrl'] as String? ?? json['imagem_url'] as String?,
      preferencias: json['preferencias'] as Map<String, dynamic>? ?? {},
      criadoEm: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'tipo': tipo,
      'perfilId': perfilId,
      'filialId': filialId,
      'imagem_url': imagemUrl,
      'preferencias': preferencias,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}
