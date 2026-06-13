import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mensagem.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  String chatId(String uid1, String uid2) {
    var sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<Mensagem>> mensagens(String chatId) {
    return _db.collection('mensagens')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((s) {
      var lista = s.docs.map((d) => Mensagem.fromMap(d.id, d.data())).toList();
      lista.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
      return lista;
    });
  }

  Future<void> enviar(Mensagem m, {required String destinatarioId, required String remetenteNome}) async {
    await _db.collection('mensagens').add(m.toMap());
    await _db.collection('avisos').add({
      'destinatarioId': destinatarioId,
      'titulo': 'Nova mensagem de $remetenteNome',
      'corpo': m.texto.length > 60 ? '${m.texto.substring(0, 60)}...' : m.texto,
      'tipo': 'mensagem',
      'consultaId': m.remetenteId,
      'lido': false,
      'criadoEm': DateTime.now().toIso8601String(),
    });
  }
}
