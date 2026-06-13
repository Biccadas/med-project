class Medicamento {
  String id;
  String pacienteId;
  String medicoId;
  String medicoNome;
  String consultaId;
  String nome;
  String dosagem;
  String frequencia;
  String dataInicio;
  String dataFim;

  Medicamento({
    required this.id,
    required this.pacienteId,
    required this.medicoId,
    required this.medicoNome,
    required this.consultaId,
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    required this.dataInicio,
    required this.dataFim,
  });

  factory Medicamento.fromMap(String id, Map<String, dynamic> d) {
    return Medicamento(
      id: id,
      pacienteId: d['pacienteId'] as String,
      medicoId: d['medicoId'] as String,
      medicoNome: d['medicoNome'] ?? '',
      consultaId: d['consultaId'] as String,
      nome: d['nome'] as String,
      dosagem: d['dosagem'] ?? '',
      frequencia: d['frequencia'] ?? '',
      dataInicio: d['dataInicio'] ?? '',
      dataFim: d['dataFim'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pacienteId': pacienteId,
      'medicoId': medicoId,
      'medicoNome': medicoNome,
      'consultaId': consultaId,
      'nome': nome,
      'dosagem': dosagem,
      'frequencia': frequencia,
      'dataInicio': dataInicio,
      'dataFim': dataFim,
    };
  }
}