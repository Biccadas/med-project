import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/utilizador.dart';
import '../../firebase_options.dart';

class AuthService {

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get utilizadorAtual => _auth.currentUser;

  Future<String?> registar(String nome, String email, String senha, String tipo,
      {String telefone = '', int? idade, String? especializacao}) async {
    try {
      var resultado = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
      String uid = resultado.user!.uid;
      Map<String, dynamic> dados = {
        'nome': nome, 'email': email, 'tipo': tipo,
        'criadoEm': DateTime.now().toIso8601String(),
        'telefone': telefone,
        if (idade != null) 'idade': idade,
        if (especializacao != null && especializacao.isNotEmpty) 'especializacao': especializacao,
      };
      await _db.collection('utilizadores').doc(uid).set(dados);
      return null;
    } on FirebaseAuthException catch (e) { return e.message; }
  }

  Future<String?> login(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) { return e.message; }
  }

  Future<void> logout() async { await _auth.signOut(); }

  Future<Utilizador?> buscarUtilizador(String uid) async {
    var doc = await _db.collection('utilizadores').doc(uid).get();
    if (doc.exists) return Utilizador.fromMap(uid, doc.data()!);
    return null;
  }

  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // cria conta sem afectar a sessão actual (usa app secundária)
  Future<String?> registarMedico(String nome, String email, String senha, String telefone, String especializacao) async {
    FirebaseApp? app;
    try {
      app = await Firebase.initializeApp(
        name: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      var result = await FirebaseAuth.instanceFor(app: app)
          .createUserWithEmailAndPassword(email: email, password: senha);
      String uid = result.user!.uid;
      await _db.collection('utilizadores').doc(uid).set({
        'nome': nome, 'email': email, 'tipo': 'medico',
        'criadoEm': DateTime.now().toIso8601String(),
        'telefone': telefone,
        'especializacao': especializacao,
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      await app?.delete();
    }
  }

  Future<void> editarPerfil(String uid, String nome, String telefone, {String? especializacao}) async {
    Map<String, dynamic> updates = {'nome': nome, 'telefone': telefone};
    if (especializacao != null) updates['especializacao'] = especializacao;
    await _db.collection('utilizadores').doc(uid).update(updates);
  }
}