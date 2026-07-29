import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/utilizador.dart';
import '../utilizador_repository.dart';

class FirebaseUtilizadorRepository implements UtilizadorRepository {

  final _db = FirebaseFirestore.instance;

  @override
  Stream<List<Utilizador>> todosUtilizadores() {
    return _db
        .collection('utilizadores')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Utilizador.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> actualizarTipo(String uid, String tipo) async {
    await _db.collection('utilizadores').doc(uid).update({'tipo': tipo});
  }

  // remover utilizador do firestore (nao remove do auth)
  @override
  Future<void> removerUtilizador(String uid) async {
    await _db.collection('utilizadores').doc(uid).delete();
  }
}
