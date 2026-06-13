class HistoricoMedico {
  String id;
  String pacienteId;
  String medicoId;
  String medicoNome;
  String diagnostico;
  String observacoes;
  String data;

  HistoricoMedico({
    required this.id,
    required this.pacienteId,
    required this.medicoId,
    required this.medicoNome,
    required this.diagnostico,
    required this.observacoes,
    required this.data,
  });

  factory HistoricoMedico.fromMap(String id, Map<String, dynamic> d) {
    return HistoricoMedico(
      id: id,
      pacienteId: d['pacienteId'] as String,
      medicoId: d['medicoId'] as String,
      medicoNome: d['medicoNome'] ?? '',
      diagnostico: d['diagnostico'] ?? '',
      observacoes: d['observacoes'] ?? '',
      data: d['data'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pacienteId': pacienteId,
      'medicoId': medicoId,
      'medicoNome': medicoNome,
      'diagnostico': diagnostico,
      'observacoes': observacoes,
      'data': data,
    };
  }
}