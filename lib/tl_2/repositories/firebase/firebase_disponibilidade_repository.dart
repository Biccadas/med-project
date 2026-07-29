import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/disponibilidade.dart';
import '../disponibilidade_repository.dart';

class FirebaseDisponibilidadeRepository implements DisponibilidadeRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Future<void> guardar(Disponibilidade d) async {
    await _db.collection('disponibilidade').doc(d.medicoId).set(d.toMap());
  }

  @override
  Future<Disponibilidade?> buscar(String medicoId) async {
    var doc = await _db.collection('disponibilidade').doc(medicoId).get();
    if (doc.exists) return Disponibilidade.fromMap(doc.data()!);
    return null;
  }

  @override
  Future<List<String>> horasDisponiveis(String medicoId, int diaSemana) async {
    var d = await buscar(medicoId);
    if (d == null) return [];
    return d.horarios[diaSemana] ?? [];
  }
}
