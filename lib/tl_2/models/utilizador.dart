class Utilizador {
  String uid;
  String nome;
  String email;
  String tipo;
  String criadoEm;
  String telefone;
  int? idade;
  String? especializacao;

  Utilizador({
    required this.uid,
    required this.nome,
    required this.email,
    required this.tipo,
    required this.criadoEm,
    this.telefone = '',
    this.idade,
    this.especializacao,
  });

  factory Utilizador.fromMap(String uid, Map<String, dynamic> d) {
    return Utilizador(
      uid: uid,
      nome: d['nome'] as String,
      email: d['email'] as String,
      tipo: d['tipo'] ?? 'paciente',
      criadoEm: d['criadoEm'] ?? '',
      telefone: d['telefone'] ?? '',
      idade: d['idade'],
      especializacao: d['especializacao'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'criadoEm': criadoEm,
      'telefone': telefone,
      if (idade != null) 'idade': idade,
      if (especializacao != null) 'especializacao': especializacao,
    };
  }
}