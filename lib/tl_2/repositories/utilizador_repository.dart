import '../models/utilizador.dart';

abstract class UtilizadorRepository {
  Stream<List<Utilizador>> todosUtilizadores();
  Future<void> actualizarTipo(String uid, String tipo);
  Future<void> removerUtilizador(String uid);
}
