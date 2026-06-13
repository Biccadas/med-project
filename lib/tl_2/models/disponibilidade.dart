class Disponibilidade {
  String medicoId;
  Map<int, List<String>> horarios;

  Disponibilidade({required this.medicoId, required this.horarios});

  factory Disponibilidade.fromMap(Map<String, dynamic> d) {
    Map<int, List<String>> h = {};
    var raw = d['horarios'] as Map<String, dynamic>? ?? {};
    raw.forEach((k, v) {
      h[int.parse(k)] = List<String>.from(v);
    });
    return Disponibilidade(medicoId: d['medicoId'] ?? '', horarios: h);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> h = {};
    horarios.forEach((k, v) { h[k.toString()] = v; });
    return {'medicoId': medicoId, 'horarios': h};
  }
}