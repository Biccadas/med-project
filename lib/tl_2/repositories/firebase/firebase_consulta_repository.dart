import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/consulta.dart';
import '../../models/utilizador.dart';
import '../../models/aviso.dart';
import '../consulta_repository.dart';

class FirebaseConsultaRepository implements ConsultaRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Future<String?> marcarConsulta(Consulta c) async {
    try {
      var doc = await _db.collection('consultas').add(c.toMap());
      if (c.estado == 'confirmada' && c.pacienteId.isNotEmpty) {
        await _criarAviso(Aviso(id: '', destinatarioId: c.pacienteId,
            titulo: 'Nova consulta agendada',
            corpo: 'Dr. ${c.medicoNome} agendou uma consulta para ${c.data} às ${c.hora}',
            tipo: 'consulta_confirmada', consultaId: doc.id,
            criadoEm: DateTime.now().toIso8601String()));
      }
      return null;
    } catch (e) { return e.toString(); }
  }

  @override
  Stream<List<Consulta>> consultasActivasPaciente(String uid) {
    return _db.collection('consultas')
        .where('pacienteId', isEqualTo: uid)
        .where('estado', whereIn: ['pendente', 'confirmada'])
        .snapshots()
        .map((s) => s.docs.map((d) => Consulta.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Consulta>> historicoPaciente(String uid) {
    return _db.collection('consultas')
        .where('pacienteId', isEqualTo: uid)
        .where('estado', whereIn: ['realizada', 'cancelada'])
        .snapshots()
        .map((s) => s.docs.map((d) => Consulta.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Consulta>> consultasActivasMedico(String uid) {
    return _db.collection('consultas')
        .where('medicoId', isEqualTo: uid)
        .where('estado', whereIn: ['pendente', 'confirmada'])
        .snapshots()
        .map((s) => s.docs.map((d) => Consulta.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Consulta>> historicoMedico(String uid) {
    return _db.collection('consultas')
        .where('medicoId', isEqualTo: uid)
        .where('estado', whereIn: ['realizada', 'cancelada'])
        .snapshots()
        .map((s) => s.docs.map((d) => Consulta.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Consulta>> todasConsultas() {
    return _db.collection('consultas').snapshots()
        .map((s) => s.docs.map((d) => Consulta.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> actualizarEstado(String id, String estado, {String pacienteId = '', String medicoId = '', String pacienteNome = '', String medicoNome = '', String data = '', String hora = ''}) async {
    await _db.collection('consultas').doc(id).update({'estado': estado});

    // criar aviso para paciente
    if (pacienteId.isNotEmpty && (estado == 'confirmada' || estado == 'cancelada' || estado == 'realizada')) {
      String titulo = estado == 'confirmada' ? 'Consulta confirmada'
          : estado == 'cancelada' ? 'Consulta cancelada' : 'Consulta realizada';
      String corpo = estado == 'confirmada'
          ? 'A sua consulta de $data às $hora foi confirmada por Dr. $medicoNome'
          : estado == 'cancelada'
          ? 'A sua consulta de $data às $hora foi cancelada'
          : 'A sua consulta de $data às $hora foi marcada como realizada';
      await _criarAviso(Aviso(id: '', destinatarioId: pacienteId, titulo: titulo, corpo: corpo, tipo: 'consulta_$estado', consultaId: id, criadoEm: DateTime.now().toIso8601String()));
    }

    // aviso para medico quando paciente marca
    if (medicoId.isNotEmpty && estado == 'pendente') {
      await _criarAviso(Aviso(id: '', destinatarioId: medicoId, titulo: 'Nova consulta agendada', corpo: '$pacienteNome agendou uma consulta para $data às $hora', tipo: 'nova_consulta', consultaId: id, criadoEm: DateTime.now().toIso8601String()));
    }
  }

  Future<void> _criarAviso(Aviso a) async {
    await _db.collection('avisos').add(a.toMap());
  }

  @override
  Future<void> criarAvisoExame(String pacienteId, String consultaId, String detalhe) async {
    await _criarAviso(Aviso(id: '', destinatarioId: pacienteId, titulo: 'Resultado de exame disponível', corpo: detalhe, tipo: 'exame', consultaId: consultaId, criadoEm: DateTime.now().toIso8601String()));
  }

  @override
  Future<void> guardarDetalheConsulta(String id, String diag, String obs, List<String> exames, List<String> resultadosExames) async {
    await _db.collection('consultas').doc(id).update({
      'diagnostico': diag, 'observacoes': obs, 'exames': exames, 'resultadosExames': resultadosExames,
    });
  }

  @override
  Future<void> actualizarPagamento(String id, String estado, double valor, String metodo, {String seguradoraCodigo = ''}) async {
    await _db.collection('consultas').doc(id).update({
      'pagamentoEstado': estado, 'pagamentoValor': valor, 'pagamentoMetodo': metodo,
      if (seguradoraCodigo.isNotEmpty) 'seguradoraCodigo': seguradoraCodigo,
    });
  }

  @override
  Future<void> editarConsulta(String id, String data, String hora, String motivo) async {
    await _db.collection('consultas').doc(id).update({'data': data, 'hora': hora, 'motivo': motivo});
  }

  @override
  Future<void> eliminarConsulta(String id) async {
    await _db.collection('consultas').doc(id).delete();
  }

  @override
  Future<List<Utilizador>> buscarMedicos() async {
    var snap = await _db.collection('utilizadores').where('tipo', isEqualTo: 'medico').get();
    return snap.docs.map((d) => Utilizador.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<List<Utilizador>> buscarPacientes() async {
    var snap = await _db.collection('utilizadores').where('tipo', isEqualTo: 'paciente').get();
    return snap.docs.map((d) => Utilizador.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<List<Utilizador>> buscarPacientesDoMedico(String medicoId) async {
    var snap = await _db.collection('consultas').where('medicoId', isEqualTo: medicoId).get();
    List<String> ids = [];
    for (var d in snap.docs) {
      String pid = d.data()['pacienteId'] ?? '';
      if (pid.isNotEmpty && !ids.contains(pid)) ids.add(pid);
    }
    List<Utilizador> lista = [];
    for (var id in ids) {
      var doc = await _db.collection('utilizadores').doc(id).get();
      if (doc.exists) lista.add(Utilizador.fromMap(doc.id, doc.data()!));
    }
    return lista;
  }

  @override
  Future<List<Consulta>> consultasConfirmadasPaciente(String pacienteId) async {
    var snap = await _db.collection('consultas')
        .where('pacienteId', isEqualTo: pacienteId)
        .where('estado', whereIn: ['confirmada', 'realizada']).get();
    return snap.docs.map((d) => Consulta.fromMap(d.id, d.data())).toList();
  }

  @override
  Stream<List<Aviso>> avisosNaoLidos(String uid) {
    return _db.collection('avisos')
        .where('destinatarioId', isEqualTo: uid)
        .where('lido', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Aviso.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<Aviso>> todosAvisos(String uid) {
    return _db.collection('avisos')
        .where('destinatarioId', isEqualTo: uid)
        .snapshots()
        .map((s) {
      var lista = s.docs.map((d) => Aviso.fromMap(d.id, d.data())).toList();
      lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return lista;
    });
  }

  @override
  Future<void> marcarAvisoLido(String id) async {
    await _db.collection('avisos').doc(id).update({'lido': true});
  }

  @override
  Future<void> marcarTodosLidos(String uid) async {
    var snap = await _db.collection('avisos').where('destinatarioId', isEqualTo: uid).where('lido', isEqualTo: false).get();
    for (var d in snap.docs) { await d.reference.update({'lido': true}); }
  }
}
