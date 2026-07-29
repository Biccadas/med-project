import '../models/disponibilidade.dart';

abstract class DisponibilidadeRepository {
  Future<void> guardar(Disponibilidade d);
  Future<Disponibilidade?> buscar(String medicoId);
  Future<List<String>> horasDisponiveis(String medicoId, int diaSemana);
}
