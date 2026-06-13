class Consulta {
  String id;
  String pacienteId;
  String pacienteNome;
  String medicoId;
  String medicoNome;
  String medicoEspec;
  String data;
  String hora;
  String motivo;
  String estado;
  String diagnostico;
  String observacoes;
  List<String> exames;
  List<String> resultadosExames;
  String pagamentoEstado;
  double pagamentoValor;
  String pagamentoMetodo;
  String seguradoraCodigo;   // dinheiro, mpesa, emola

  Consulta({
    required this.id,
    required this.pacienteId,
    required this.pacienteNome,
    required this.medicoId,
    required this.medicoNome,
    this.medicoEspec = '',
    required this.data,
    required this.hora,
    required this.motivo,
    required this.estado,
    this.diagnostico = '',
    this.observacoes = '',
    this.exames = const [],
    this.resultadosExames = const [],
    this.pagamentoEstado = 'pendente',
    this.pagamentoValor = 0,
    this.pagamentoMetodo = '',
    this.seguradoraCodigo = '',
  });

  factory Consulta.fromMap(String id, Map<String, dynamic> d) {
    return Consulta(
      id: id,
      pacienteId: d['pacienteId'] as String,
      pacienteNome: d['pacienteNome'] as String,
      medicoId: d['medicoId'] as String,
      medicoNome: d['medicoNome'] as String,
      medicoEspec: d['medicoEspec'] ?? '',
      data: d['data'] as String,
      hora: d['hora'] as String,
      motivo: d['motivo'] ?? '',
      estado: d['estado'] ?? 'pendente',
      diagnostico: d['diagnostico'] ?? '',
      observacoes: d['observacoes'] ?? '',
      exames: List<String>.from(d['exames'] ?? []),
      resultadosExames: List<String>.from(d['resultadosExames'] ?? []),
      pagamentoEstado: d['pagamentoEstado'] ?? 'pendente',
      pagamentoValor: (d['pagamentoValor'] ?? 0).toDouble(),
      pagamentoMetodo: d['pagamentoMetodo'] ?? '',
      seguradoraCodigo: d['seguradoraCodigo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pacienteId': pacienteId,
      'pacienteNome': pacienteNome,
      'medicoId': medicoId,
      'medicoNome': medicoNome,
      'medicoEspec': medicoEspec,
      'data': data,
      'hora': hora,
      'motivo': motivo,
      'estado': estado,
      'diagnostico': diagnostico,
      'observacoes': observacoes,
      'exames': exames,
      'resultadosExames': resultadosExames,
      'pagamentoEstado': pagamentoEstado,
      'pagamentoValor': pagamentoValor,
      'pagamentoMetodo': pagamentoMetodo,
      if (seguradoraCodigo.isNotEmpty) 'seguradoraCodigo': seguradoraCodigo,
    };
  }
}