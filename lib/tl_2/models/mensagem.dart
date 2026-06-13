class Mensagem {
  String id;
  String chatId;
  String remetenteId;
  String texto;
  String criadoEm;

  Mensagem({
    required this.id,
    required this.chatId,
    required this.remetenteId,
    required this.texto,
    required this.criadoEm,
  });

  factory Mensagem.fromMap(String id, Map<String, dynamic> d) {
    return Mensagem(
      id: id,
      chatId: d['chatId'] as String,
      remetenteId: d['remetenteId'] as String,
      texto: d['texto'] as String,
      criadoEm: d['criadoEm'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'chatId': chatId,
    'remetenteId': remetenteId,
    'texto': texto,
    'criadoEm': criadoEm,
  };
}
