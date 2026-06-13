import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/disponibilidade.dart';

class DisponibilidadeService {
  final _db = FirebaseFirestore.instance;

  Future<void> guardar(Disponibilidade d) async {
    await _db.collection('disponibilidade').doc(d.medicoId).set(d.toMap());
  }

  Future<Disponibilidade?> buscar(String medicoId) async {
    var doc = await _db.collection('disponibilidade').doc(medicoId).get();
    if (doc.exists) return Disponibilidade.fromMap(doc.data()!);
    return null;
  }

  Future<List<String>> horasDisponiveis(String medicoId, int diaSemana) async {
    var d = await buscar(medicoId);
    if (d == null) return [];
    return d.horarios[diaSemana] ?? [];
  }
}