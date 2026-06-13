class Aviso {
  String id;
  String destinatarioId;
  String titulo;
  String corpo;
  String tipo;  // consulta_confirmada, consulta_cancelada, exame, consulta_realizada
  String consultaId;
  bool lido;
  String criadoEm;

  Aviso({
    required this.id,
    required this.destinatarioId,
    required this.titulo,
    required this.corpo,
    required this.tipo,
    required this.consultaId,
    this.lido = false,
    required this.criadoEm,
  });

  factory Aviso.fromMap(String id, Map<String, dynamic> d) {
    return Aviso(
      id: id,
      destinatarioId: d['destinatarioId'] as String,
      titulo: d['titulo'] as String,
      corpo: d['corpo'] as String,
      tipo: d['tipo'] as String,
      consultaId: d['consultaId'] ?? '',
      lido: d['lido'] ?? false,
      criadoEm: d['criadoEm'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'destinatarioId': destinatarioId,
    'titulo': titulo,
    'corpo': corpo,
    'tipo': tipo,
    'consultaId': consultaId,
    'lido': lido,
    'criadoEm': criadoEm,
  };
}