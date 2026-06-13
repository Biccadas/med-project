import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicamento.dart';

class HistoricoService {

  final _db = FirebaseFirestore.instance;

  Future<String?> adicionarMedicamento(Medicamento m) async {
    try {
      await _db.collection('medicamentos').add(m.toMap());
      return null;
    } catch (e) { return e.toString(); }
  }

  Stream<List<Medicamento>> medicamentosDoPaciente(String pacienteId) {
    return _db.collection('medicamentos').where('pacienteId', isEqualTo: pacienteId)
        .snapshots().map((s) => s.docs.map((d) => Medicamento.fromMap(d.id, d.data())).toList());
  }

  Future<List<Medicamento>> medicamentosDaConsulta(String consultaId) async {
    var snap = await _db.collection('medicamentos').where('consultaId', isEqualTo: consultaId).get();
    return snap.docs.map((d) => Medicamento.fromMap(d.id, d.data())).toList();
  }

  Future<void> removerMedicamento(String id) async {
    await _db.collection('medicamentos').doc(id).delete();
  }
}