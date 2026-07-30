import '../models/consulta.dart';
import '../models/aviso.dart';
import '../models/utilizador.dart';

abstract class ConsultaRepository {
  Future<String?> marcarConsulta(Consulta c);

  Stream<List<Consulta>> consultasActivasPaciente(String uid);
  Stream<List<Consulta>> historicoPaciente(String uid);
  Stream<List<Consulta>> consultasActivasMedico(String uid);
  Stream<List<Consulta>> historicoMedico(String uid);
  Stream<List<Consulta>> todasConsultas();

  Future<void> actualizarEstado(String id, String estado, {String pacienteId = '', String medicoId = '', String pacienteNome = '', String medicoNome = '', String data = '', String hora = ''});

  Future<void> criarAvisoExame(String pacienteId, String consultaId, String detalhe);
  Future<void> guardarDetalheConsulta(String id, String diag, String obs, List<String> exames, List<String> resultadosExames);
  Future<void> actualizarPagamento(String id, String estado, double valor, String metodo, {String seguradoraCodigo = ''});
  Future<void> editarConsulta(String id, String data, String hora, String motivo);
  Future<void> eliminarConsulta(String id);

  Future<List<Utilizador>> buscarMedicos();
  Future<List<Utilizador>> buscarPacientes();
  Future<List<Utilizador>> buscarPacientesDoMedico(String medicoId);
  Future<List<Consulta>> consultasConfirmadasPaciente(String pacienteId);

  Stream<List<Aviso>> avisosNaoLidos(String uid);
  Stream<List<Aviso>> todosAvisos(String uid);
  Future<void> marcarAvisoLido(String id);
  Future<void> marcarTodosLidos(String uid);
}
