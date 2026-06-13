import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/consulta_service.dart';
import '../../services/historico_service.dart';
import '../../services/disponibilidade_service.dart';
import '../../models/consulta.dart';
import '../../models/medicamento.dart';
import '../../models/utilizador.dart';
import '../../models/disponibilidade.dart';
import '../../core/tema.dart';
import '../shared/chat_tela.dart';

class MedicoTela extends StatefulWidget {
  const MedicoTela({super.key});
  @override
  State<MedicoTela> createState() => _MedicoTelaState();
}

class _MedicoTelaState extends State<MedicoTela> {
  final _cs = ConsultaService();
  final _hs = HistoricoService();
  final _ds = DisponibilidadeService();
  int _tab = 0;
  String _filtroEstado = 'todos';
  String _pesquisa = '';
  DateTime? _dataInicio; DateTime? _dataFim;
  bool _kpiVisivel = true;
  final _scrollInicio = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollInicio.addListener(() {
      final esconder = _scrollInicio.offset > 60;
      if (esconder == _kpiVisivel) setState(() { _kpiVisivel = !esconder; });
    });
  }

  @override
  void dispose() {
    _scrollInicio.dispose();
    super.dispose();
  }
  final _txtPesquisa = TextEditingController();

  static const dosagens = ['50mg','100mg','200mg','250mg','400mg','500mg','600mg','750mg','1g','2g','5ml','10ml','15ml','20ml'];
  static const examesDisponiveis = ['Hemograma Completo','Glicemia','Colesterol Total','Triglicerídeos','Ureia e Creatinina','Radiografia Torácica','Ecografia Abdominal','Electrocardiograma','TAC Craniana','Ressonância Magnética','Biopsia','PSA','TSH / T4','Urina Tipo II'];
  static const diasSemana = ['Seg','Ter','Qua','Qui','Sex','Sáb','Dom'];
  static const horasPadrao = ['08:00','08:30','09:00','09:30','10:00','10:30','11:00','11:30','14:00','14:30','15:00','15:30','16:00','16:30','17:00'];
  static const metodosPagamento = ['dinheiro', 'mpesa', 'emola', 'seguradora', 'Cartão'];
  static const seguradoras = ['MedPlus', 'MediHealth', 'Holland Health', 'Fidelidade'];


  void abrirAgendarConsulta(AuthProvider prov) async {
    var pacientes = await _cs.buscarPacientes();
    if (pacientes.isEmpty) { _snack('Nenhum paciente disponível', MedColors.warning); return; }
    Utilizador? pacSel; DateTime? dataSel; TimeOfDay? horaSel; var txtMotivo = TextEditingController(); String erro = '';
    _sheet((ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sheetHandle(), SizedBox(height: 16),
      Text('Agendar Consulta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      SizedBox(height: 20),
      sheetDropdown<Utilizador>('Seleccionar paciente', pacSel, pacientes.map((p) => DropdownMenuItem(value: p, child: Text(p.nome))).toList(), (v) => setS(() { pacSel = v; })),
      SizedBox(height: 10),
      datePicker(ctx, dataSel, 'Data da consulta', (d) => setS(() { dataSel = d; })),
      SizedBox(height: 10),
      timePicker(ctx, horaSel, 'Seleccionar hora', (h) => setS(() { horaSel = h; })),
      SizedBox(height: 10),
      sheetField(txtMotivo, 'Motivo'),
      if (erro.isNotEmpty) ...[SizedBox(height: 8), Text(erro, style: TextStyle(color: MedColors.danger, fontSize: 12))],
      SizedBox(height: 20),
      MedButton(label: 'Confirmar Consulta', onPressed: () async {
        if (pacSel == null || dataSel == null || horaSel == null || txtMotivo.text.isEmpty) {
          setS(() { erro = 'Preencha todos os campos.'; }); return;
        }
        String dataStr = formatarData(dataSel!);
        await _cs.marcarConsulta(Consulta(id: '', pacienteId: pacSel!.uid, pacienteNome: pacSel!.nome,
            medicoId: prov.utilizador!.uid, medicoNome: prov.utilizador!.nome, medicoEspec: prov.utilizador!.especializacao ?? '',
            data: dataStr, hora: '${horaSel!.hour.toString().padLeft(2, '0')}:${horaSel!.minute.toString().padLeft(2, '0')}', motivo: txtMotivo.text.trim(), estado: 'confirmada'));
        Navigator.pop(ctx); _snack('Consulta agendada', MedColors.success);
      }, cor: MedColors.teal),
      SizedBox(height: 8),
    ]));
  }

  void abrirPreencherConsulta(Consulta c, AuthProvider prov) {
    if (c.estado != 'confirmada') { _snack('Só consultas confirmadas podem ser preenchidas', MedColors.warning); return; }
    var txtDiag = TextEditingController(text: c.diagnostico);
    var txtObs = TextEditingController(text: c.observacoes);
    List<String> examesSel = List.from(c.exames);
    List<String> resultados = List.from(c.resultadosExames);
    var txtResult = TextEditingController();
    var txtMedNome = TextEditingController(); String? dosaSel; var txtFreq = TextEditingController();
    DateTime? dataIni; DateTime? dataFim; String erro = '';
    String? metodoPag = c.pagamentoMetodo.isNotEmpty ? c.pagamentoMetodo : null;
    String? seguradoraSel;
    var txtValor = TextEditingController(text: c.pagamentoValor > 0 ? c.pagamentoValor.toStringAsFixed(0) : '');
    var txtSegCodigo = TextEditingController(text: c.seguradoraCodigo);
    bool pagRegistado = c.pagamentoEstado == 'pago'; String erroPag = '';

    showModalBottomSheet(context: context, isScrollControlled: true, isDismissible: true, enableDrag: true, backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => DraggableScrollableSheet(
            initialChildSize: .9, maxChildSize: .97, minChildSize: .5,
            builder: (ctx, scroll) => Container(
              decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(children: [
                Padding(padding: EdgeInsets.fromLTRB(20, 14, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: MedColors.border, borderRadius: BorderRadius.circular(2)))),
                  SizedBox(height: 14),
                  Text('Consulta de ${c.pacienteNome}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MedColors.text)),
                  Text('${c.data}  ·  ${c.hora}  ·  ${c.motivo}', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
                ])),
                Divider(height: 20, color: MedColors.border),
                Expanded(child: ListView(controller: scroll, padding: EdgeInsets.symmetric(horizontal: 20), children: [

                  Text('Diagnóstico', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedColors.text)),
                  SizedBox(height: 8),
                  sheetField(txtDiag, 'Diagnóstico'),
                  SizedBox(height: 8),
                  sheetField(txtObs, 'Observações clínicas', maxLines: 3),

                  SizedBox(height: 20),
                  Text('Exames a Pedir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedColors.text)),
                  SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: examesDisponiveis.map((e) {
                    bool sel = examesSel.contains(e);
                    return GestureDetector(onTap: () => setS(() { sel ? examesSel.remove(e) : examesSel.add(e); }),
                        child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: sel ? MedColors.accent : MedColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? MedColors.accent : MedColors.border)),
                            child: Text(e, style: TextStyle(fontSize: 12, color: sel ? Colors.white : MedColors.textSub, fontWeight: sel ? FontWeight.w700 : FontWeight.w400))));
                  }).toList()),

                  SizedBox(height: 16),
                  Text('Resultados de Exames', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedColors.text)),
                  SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: sheetField(txtResult, 'Descrever resultado...')),
                    SizedBox(width: 8),
                    ElevatedButton(onPressed: () {
                      if (txtResult.text.isNotEmpty) { setS(() { resultados.add(txtResult.text.trim()); txtResult.clear(); }); }
                    }, style: ElevatedButton.styleFrom(backgroundColor: MedColors.teal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text('+ Add')),
                  ]),
                  if (resultados.isNotEmpty) ...[SizedBox(height: 8),
                    ...resultados.map((r) => Container(margin: EdgeInsets.only(bottom: 6), padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(color: MedColors.tealLight, borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [Icon(Icons.science_outlined, color: MedColors.teal, size: 14), SizedBox(width: 8),
                          Expanded(child: Text(r, style: TextStyle(fontSize: 12, color: MedColors.text))),
                          GestureDetector(onTap: () => setS(() { resultados.remove(r); }), child: Icon(Icons.close_rounded, size: 14, color: MedColors.textHint))])))],

                  SizedBox(height: 20),
                  Text('Prescrever Medicamento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedColors.text)),
                  SizedBox(height: 8),
                  sheetField(txtMedNome, 'Nome do medicamento'),
                  SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Container(padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: MedColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border, width: 1.5)),
                        child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true,
                            hint: Text('Dosagem', style: TextStyle(color: MedColors.textHint, fontSize: 13)),
                            value: dosaSel, items: dosagens.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (v) => setS(() { dosaSel = v; }))))),
                    SizedBox(width: 8),
                    Expanded(child: sheetField(txtFreq, 'Frequência')),
                  ]),
                  SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: datePicker(ctx, dataIni, 'Início', (d) => setS(() { dataIni = d; }))),
                    SizedBox(width: 8),
                    Expanded(child: datePicker(ctx, dataFim, 'Fim', (d) => setS(() { dataFim = d; }))),
                  ]),
                  SizedBox(height: 8),
                  ElevatedButton(onPressed: () async {
                    if (txtMedNome.text.isEmpty || dosaSel == null || dataIni == null || dataFim == null) {
                      setS(() { erro = 'Preencha todos os campos do medicamento.'; }); return;
                    }
                    await _hs.adicionarMedicamento(Medicamento(id: '', pacienteId: c.pacienteId,
                        medicoId: prov.utilizador!.uid, medicoNome: prov.utilizador!.nome, consultaId: c.id,
                        nome: txtMedNome.text.trim(), dosagem: dosaSel!, frequencia: txtFreq.text.trim(),
                        dataInicio: formatarData(dataIni!),
                        dataFim: formatarData(dataFim!)));
                    txtMedNome.clear(); txtFreq.clear();
                    setS(() { dosaSel = null; dataIni = null; dataFim = null; erro = ''; });
                    _snack('Medicamento adicionado', MedColors.success);
                  }, style: ElevatedButton.styleFrom(backgroundColor: MedColors.successLight, foregroundColor: MedColors.success, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: Text('+ Adicionar Medicamento')),

                  if (erro.isNotEmpty) ...[SizedBox(height: 6), Text(erro, style: TextStyle(color: MedColors.danger, fontSize: 12))],

                  SizedBox(height: 20),
                  Text('Pagamento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedColors.text)),
                  SizedBox(height: 8),
                  if (pagRegistado)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(color: MedColors.successLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.success.withOpacity(.2))),
                      child: Row(children: [
                        Icon(Icons.check_circle_rounded, color: MedColors.success, size: 18), SizedBox(width: 8),
                        Expanded(child: Text('Pago · ${c.pagamentoMetodo}${c.seguradoraCodigo.isNotEmpty ? ' · ${c.seguradoraCodigo}' : c.pagamentoValor > 0 ? ' · ${c.pagamentoValor.toStringAsFixed(0)} MZN' : ''}',
                            style: TextStyle(fontSize: 13, color: MedColors.success, fontWeight: FontWeight.w600))),
                      ]),
                    )
                  else ...[
                    sheetDropdown<String>('Método de pagamento', metodoPag,
                        metodosPagamento.map((m) => DropdownMenuItem(value: m, child: Text(m[0].toUpperCase() + m.substring(1)))).toList(),
                        (v) => setS(() { metodoPag = v; seguradoraSel = null; })),
                    if (metodoPag == 'seguradora') ...[
                      SizedBox(height: 8),
                      sheetDropdown<String>('Seguradora', seguradoraSel,
                          seguradoras.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          (v) => setS(() { seguradoraSel = v; })),
                      SizedBox(height: 8),
                      sheetField(txtSegCodigo, 'Código do beneficiário', keyboard: TextInputType.number),
                    ] else if (metodoPag != null) ...[
                      SizedBox(height: 8),
                      sheetField(txtValor, 'Valor (MZN)', keyboard: TextInputType.number),
                    ],
                    if (erroPag.isNotEmpty) ...[SizedBox(height: 6), Text(erroPag, style: TextStyle(color: MedColors.danger, fontSize: 12))],
                    if (metodoPag != null) ...[
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (metodoPag == 'seguradora' && (seguradoraSel == null || txtSegCodigo.text.isEmpty)) {
                            setS(() { erroPag = 'Seleccione a seguradora e insira o código.'; }); return;
                          }
                          double valor = metodoPag == 'seguradora' ? 0 : (double.tryParse(txtValor.text) ?? 0);
                          String codSeg = metodoPag == 'seguradora' ? '${seguradoraSel!} | ${txtSegCodigo.text.trim()}' : '';
                          await _cs.actualizarPagamento(c.id, 'pago', valor, metodoPag!, seguradoraCodigo: codSeg);
                          setS(() { pagRegistado = true; erroPag = ''; });
                          _snack('Pagamento registado', MedColors.success);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: MedColors.successLight, foregroundColor: MedColors.success, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text('Registar Pagamento', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],

                  SizedBox(height: 20),
                  MedButton(label: 'Concluir e Guardar Consulta', onPressed: () async {
                    await _cs.guardarDetalheConsulta(c.id, txtDiag.text.trim(), txtObs.text.trim(), examesSel, resultados);
                    await _cs.actualizarEstado(c.id, 'realizada', pacienteId: c.pacienteId, medicoId: c.medicoId,
                        pacienteNome: c.pacienteNome, medicoNome: c.medicoNome, data: c.data, hora: c.hora);
                    if (resultados.isNotEmpty) {
                      await _cs.criarAvisoExame(c.pacienteId, c.id, 'Resultados disponíveis para a consulta de ${c.data}');
                    }
                    Navigator.pop(ctx);
                    _snack('Consulta concluída', MedColors.success);
                    _perguntarProximaConsulta(c, prov);
                  }, cor: MedColors.teal),
                  SizedBox(height: 24),
                ])),
              ]),
            ))));
  }

  void _perguntarProximaConsulta(Consulta c, AuthProvider prov) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Agendar próxima consulta?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      content: Text('Deseja agendar já a próxima consulta para ${c.pacienteNome}?', style: TextStyle(color: MedColors.textSub, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Agora não', style: TextStyle(color: MedColors.textSub))),
        ElevatedButton(onPressed: () { Navigator.pop(context); _agendarProxima(c, prov); },
            style: ElevatedButton.styleFrom(backgroundColor: MedColors.teal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Agendar', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ));
  }

  void _agendarProxima(Consulta anterior, AuthProvider prov) {
    DateTime? dataSel; TimeOfDay? horaSel2; var txtMotivo = TextEditingController(text: anterior.motivo); String erro = '';
    _sheet((ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sheetHandle(), SizedBox(height: 16),
      Text('Próxima Consulta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      Text('Paciente: ${anterior.pacienteNome}', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
      SizedBox(height: 20),
      datePicker(ctx, dataSel, 'Data da próxima consulta', (d) => setS(() { dataSel = d; })),
      SizedBox(height: 10),
      timePicker(ctx, horaSel2, 'Seleccionar hora', (h) => setS(() { horaSel2 = h; })),
      SizedBox(height: 10),
      sheetField(txtMotivo, 'Motivo'),
      if (erro.isNotEmpty) ...[SizedBox(height: 8), Text(erro, style: TextStyle(color: MedColors.danger, fontSize: 12))],
      SizedBox(height: 20),
      MedButton(label: 'Confirmar', onPressed: () async {
        if (dataSel == null || horaSel2 == null) { setS(() { erro = 'Seleccione data e hora.'; }); return; }
        String dataStr = formatarData(dataSel!);
        await _cs.marcarConsulta(Consulta(id: '', pacienteId: anterior.pacienteId, pacienteNome: anterior.pacienteNome,
            medicoId: prov.utilizador!.uid, medicoNome: prov.utilizador!.nome, medicoEspec: prov.utilizador!.especializacao ?? '',
            data: dataStr, hora: '${horaSel2!.hour.toString().padLeft(2, '0')}:${horaSel2!.minute.toString().padLeft(2, '0')}', motivo: txtMotivo.text.trim(), estado: 'confirmada'));
        Navigator.pop(ctx); _snack('Próxima consulta agendada', MedColors.success);
      }, cor: MedColors.teal),
      SizedBox(height: 8),
    ]));
  }

  void abrirProntuario(Utilizador pac) async {
    var consultas = await _cs.consultasConfirmadasPaciente(pac.uid);
    showModalBottomSheet(context: context, isScrollControlled: true, isDismissible: true, enableDrag: true, backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(initialChildSize: .85, maxChildSize: .97, minChildSize: .5,
            builder: (ctx, scroll) => Container(
              decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(children: [
                Padding(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: MedColors.border, borderRadius: BorderRadius.circular(2)))),
                  SizedBox(height: 14),
                  Row(children: [
                    Container(width: 52, height: 52, decoration: BoxDecoration(color: MedColors.accentLight, borderRadius: BorderRadius.circular(14)),
                        child: Center(child: Text(pac.nome[0].toUpperCase(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MedColors.accent)))),
                    SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(pac.nome, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MedColors.text)),
                      Text(pac.email, style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                    ]),
                  ]),
                  SizedBox(height: 12),
                  Row(children: [
                    _infoChip(Icons.phone_outlined, pac.telefone.isEmpty ? 'N/D' : pac.telefone),
                    SizedBox(width: 8),
                    _infoChip(Icons.cake_outlined, pac.idade != null ? '${pac.idade} anos' : 'N/D'),
                  ]),
                  SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(
                    onPressed: () {
                      final prov = Provider.of<AuthProvider>(context, listen: false);
                      final uid = prov.utilizador?.uid ?? '';
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatTela(
                        meuId: uid, meuNome: prov.utilizador?.nome ?? '', outroId: pac.uid, outroNome: pac.nome,
                      )));
                    },
                    icon: Icon(Icons.chat_rounded, size: 16),
                    label: Text('Enviar mensagem'),
                    style: OutlinedButton.styleFrom(foregroundColor: MedColors.teal, side: BorderSide(color: MedColors.teal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                ])),
                Divider(height: 1, color: MedColors.border),
                Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, 4), child: Text('Prontuário Médico', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MedColors.text))),
                Expanded(child: ListView(controller: scroll, padding: EdgeInsets.symmetric(horizontal: 20), children: [
                  if (consultas.isEmpty) _empty('Sem histórico clínico', '')
                  else ...consultas.map((c) => Container(
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: MedColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: MedColors.border)),
                      child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                            title: Text('${c.data}  ·  ${c.hora}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            subtitle: Text(c.motivo, style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                            children: [
                              if (c.diagnostico.isNotEmpty) _detalheRow('Diagnóstico', c.diagnostico),
                              if (c.observacoes.isNotEmpty) _detalheRow('Observações', c.observacoes),
                              if (c.exames.isNotEmpty) ...[SizedBox(height: 8),
                                Text('Exames:', style: TextStyle(fontSize: 12, color: MedColors.textSub, fontWeight: FontWeight.w600)),
                                SizedBox(height: 6),
                                Wrap(spacing: 6, runSpacing: 6, children: c.exames.map((e) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: MedColors.accentLight, borderRadius: BorderRadius.circular(20)),
                                    child: Text(e, style: TextStyle(fontSize: 11, color: MedColors.accent, fontWeight: FontWeight.w600)))).toList())],
                              FutureBuilder<List<Medicamento>>(
                                  future: _hs.medicamentosDaConsulta(c.id),
                                  builder: (ctx, snap) {
                                    var meds = snap.data ?? [];
                                    if (meds.isEmpty) return SizedBox.shrink();
                                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      SizedBox(height: 10),
                                      Text('Medicação:', style: TextStyle(fontSize: 12, color: MedColors.textSub, fontWeight: FontWeight.w600)),
                                      SizedBox(height: 6),
                                      ...meds.map((m) => Container(margin: EdgeInsets.only(bottom: 6), padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(color: MedColors.successLight, borderRadius: BorderRadius.circular(10)),
                                          child: Row(children: [Icon(Icons.medication_rounded, color: MedColors.success, size: 14), SizedBox(width: 8),
                                            Text('${m.nome}  ·  ${m.dosagem}  ·  ${m.frequencia}', style: TextStyle(fontSize: 12))]))),
                                    ]);
                                  }),
                            ],
                          )))),
                ])),
              ]),
            )));
  }

  void abrirDisponibilidade(String medicoId) async {
    var disp = await _ds.buscar(medicoId) ?? Disponibilidade(medicoId: medicoId, horarios: {});
    Map<int, List<String>> horariosCopy = {};
    disp.horarios.forEach((k, v) { horariosCopy[k] = List.from(v); });
    int diaSel = 0;
    _sheet((ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sheetHandle(), SizedBox(height: 16),
      Text('Minha Disponibilidade', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      SizedBox(height: 16),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(7, (i) {
        bool sel = diaSel == i;
        return GestureDetector(onTap: () => setS(() { diaSel = i; }),
            child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: sel ? MedColors.teal : MedColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? MedColors.teal : MedColors.border)),
                child: Text(diasSemana[i], style: TextStyle(fontSize: 13, color: sel ? Colors.white : MedColors.textSub, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
      }))),
      SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: horasPadrao.map((h) {
        var horas = horariosCopy[diaSel] ?? [];
        bool sel = horas.contains(h);
        return GestureDetector(onTap: () => setS(() {
          horariosCopy[diaSel] ??= [];
          sel ? horariosCopy[diaSel]!.remove(h) : horariosCopy[diaSel]!.add(h);
        }),
            child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: sel ? MedColors.teal : MedColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? MedColors.teal : MedColors.border)),
                child: Text(h, style: TextStyle(fontSize: 12, color: sel ? Colors.white : MedColors.textSub, fontWeight: sel ? FontWeight.w700 : FontWeight.w400))));
      }).toList()),
      SizedBox(height: 20),
      MedButton(label: 'Guardar Disponibilidade', onPressed: () async {
        await _ds.guardar(Disponibilidade(medicoId: medicoId, horarios: horariosCopy));
        Navigator.pop(ctx); _snack('Disponibilidade guardada', MedColors.success);
      }, cor: MedColors.teal),
      SizedBox(height: 8),
    ]));
  }

  void _sheet(Widget Function(BuildContext, StateSetter) builder) {
    showModalBottomSheet(context: context, isScrollControlled: true, isDismissible: true, enableDrag: true, backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Padding(padding: EdgeInsets.all(24), child: builder(ctx, setS)))));
  }

  void _snack(String msg, Color cor) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
  Widget _sheetHandle() => Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: MedColors.border, borderRadius: BorderRadius.circular(2))));
  Widget _infoChip(IconData icon, String texto) => Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: MedColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: MedColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: MedColors.textSub), SizedBox(width: 6), Text(texto, style: TextStyle(fontSize: 13, color: MedColors.text, fontWeight: FontWeight.w500))]));
  Widget _detalheRow(String l, String v) => Padding(padding: EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$l:  ', style: TextStyle(fontSize: 13, color: MedColors.textSub, fontWeight: FontWeight.w600)),
        Expanded(child: Text(v, style: TextStyle(fontSize: 13, color: MedColors.text, fontWeight: FontWeight.w500)))]));
  Widget _empty(String t, String s) => Center(child: Padding(padding: EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 64, height: 64, decoration: BoxDecoration(color: MedColors.tealLight, borderRadius: BorderRadius.circular(18)), child: Icon(Icons.inbox_rounded, color: MedColors.teal, size: 28)),
    SizedBox(height: 16), Text(t, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: MedColors.text)),
    if (s.isNotEmpty) ...[SizedBox(height: 6), Text(s, style: TextStyle(fontSize: 13, color: MedColors.textSub), textAlign: TextAlign.center)]])));

  List<Consulta> _filtrar(List<Consulta> lista) {
    var r = lista;
    if (_filtroEstado != 'todos') r = r.where((c) => c.estado == _filtroEstado).toList();
    if (_pesquisa.isNotEmpty) r = r.where((c) => c.pacienteNome.toLowerCase().contains(_pesquisa.toLowerCase())).toList();
    return _filtrarPorData(r);
  }

  List<Consulta> _filtrarPorData(List<Consulta> lista) {
    if (_dataInicio == null && _dataFim == null) return lista;
    return lista.where((c) {
      final d = parsearData(c.data);
      if (d == null) return true;
      if (_dataInicio != null && d.isBefore(_dataInicio!)) return false;
      if (_dataFim != null && d.isAfter(_dataFim!)) return false;
      return true;
    }).toList();
  }

  Widget _filtroData() {
    return Row(children: [
      Expanded(child: datePicker(context, _dataInicio, 'De', (d) => setState(() { _dataInicio = d; }), allowPast: true)),
      SizedBox(width: 8),
      Expanded(child: datePicker(context, _dataFim, 'Até', (d) => setState(() { _dataFim = d; }), allowPast: true)),
      if (_dataInicio != null || _dataFim != null) ...[
        SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() { _dataInicio = null; _dataFim = null; }),
          child: Container(padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: MedColors.dangerLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.clear_rounded, color: MedColors.danger, size: 16)),
        ),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var prov = Provider.of<AuthProvider>(context);
    String uid = prov.utilizador?.uid ?? '';
    String primeiro = prov.utilizador?.nome.split(' ').first ?? '';
    String espec = prov.utilizador?.especializacao ?? '';

    return Scaffold(
      backgroundColor: MedColors.bg,
      body: SafeArea(child: _buildTab(prov, uid, primeiro, espec)),
      floatingActionButton: _tab == 1 ? Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: MedShadow.button),
          child: FloatingActionButton(onPressed: () => abrirAgendarConsulta(prov), backgroundColor: MedColors.teal, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Icon(Icons.add_rounded, size: 26))) : null,
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: Container(
        height: 64,
        decoration: BoxDecoration(color: MedColors.navBg, borderRadius: BorderRadius.circular(24), boxShadow: MedShadow.nav, border: Border.all(color: MedColors.border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navItem(0, Icons.home_rounded, 'Início'),
          _navItem(1, Icons.calendar_today_rounded, 'Consultas'),
          _navItem(2, Icons.history_rounded, 'Histórico'),
          _navItem(3, Icons.people_rounded, 'Pacientes'),
          _navItem(4, Icons.person_rounded, 'Perfil'),
        ])));
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool sel = _tab == index;
    return GestureDetector(onTap: () => setState(() { _tab = index; _filtroEstado = 'todos'; _pesquisa = ''; _txtPesquisa.clear(); _dataInicio = null; _dataFim = null; _kpiVisivel = true; }),
        child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.transparent),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: sel ? MedColors.teal : MedColors.textHint, size: 22),
              SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 10, color: sel ? MedColors.teal : MedColors.textHint, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
            ])));
  }

  Widget _buildTab(AuthProvider prov, String uid, String primeiro, String espec) {
    switch (_tab) {
      case 0: return _tabInicio(prov, uid, primeiro, espec);
      case 1: return _tabConsultas(prov, uid);
      case 2: return _tabHistorico(uid);
      case 3: return _tabPacientes(uid);
      case 4: return _tabPerfil(prov);
      default: return _tabInicio(prov, uid, primeiro, espec);
    }
  }

  Widget _tabInicio(AuthProvider prov, String uid, String primeiro, String espec) {
    String hoje = formatarData(DateTime.now());
    return Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 0), child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: MedColors.tealLight, borderRadius: BorderRadius.circular(13)),
            child: Icon(Icons.medical_services_rounded, color: MedColors.teal, size: 22)),
        SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dr. $primeiro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text, letterSpacing: -.3)),
          if (espec.isNotEmpty) Text(espec, style: TextStyle(fontSize: 12, color: MedColors.teal, fontWeight: FontWeight.w600)),
        ])),
        AvisosBadge(stream: _cs.avisosNaoLidos(uid), onTap: () => mostrarAvisos(context, _cs.todosAvisos(uid), _cs, uid, onTapAviso: (aviso) {
          if (aviso.tipo == 'mensagem' && aviso.consultaId.isNotEmpty) {
            final prov = Provider.of<AuthProvider>(context, listen: false);
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatTela(
              meuId: uid,
              meuNome: prov.utilizador?.nome ?? '',
              outroId: aviso.consultaId,
              outroNome: aviso.titulo.replaceFirst('Nova mensagem de ', ''),
            )));
          }
        })),
        SizedBox(width: 8),
        GestureDetector(onTap: () => abrirDisponibilidade(uid),
            child: Container(width: 40, height: 40, decoration: BoxDecoration(color: MedColors.tealLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.teal.withOpacity(.2))),
                child: Icon(Icons.schedule_rounded, color: MedColors.teal, size: 18))),
        SizedBox(width: 8),
        GestureDetector(onTap: () => prov.logout(),
            child: Container(width: 40, height: 40, decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border), boxShadow: MedShadow.card),
                child: Icon(Icons.logout_rounded, color: MedColors.textSub, size: 18))),
      ])),
      Expanded(child: StreamBuilder<List<Consulta>>(
          stream: _cs.consultasActivasMedico(uid),
          builder: (ctx, snap) {
            var lista = snap.data ?? [];
            var consultasHoje = lista.where((c) => c.data == hoje).toList();
            var pendentes = lista.where((c) => c.estado == 'pendente').length;
            var confirmadas = consultasHoje.where((c) => c.estado == 'confirmada').length;
            return SingleChildScrollView(controller: _scrollInicio, padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedSize(
                duration: Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: _kpiVisivel ? Column(children: [
                  Row(children: [
                    MedKpiCard(label: 'Consultas hoje', valor: '${consultasHoje.length}', cor: MedColors.teal, bgCor: MedColors.tealLight, icon: Icons.today_rounded),
                    SizedBox(width: 10),
                    MedKpiCard(label: 'Confirmadas hoje', valor: '$confirmadas', cor: MedColors.success, bgCor: MedColors.successLight, icon: Icons.check_circle_outline_rounded),
                  ]),
                  SizedBox(height: 10),
                  Row(children: [
                    MedKpiCard(label: 'Pendentes', valor: '$pendentes', cor: MedColors.warning, bgCor: MedColors.warningLight, icon: Icons.pending_outlined),
                    SizedBox(width: 10),
                    MedKpiCard(label: 'Total activas', valor: '${lista.length}', cor: MedColors.accent, bgCor: MedColors.accentLight, icon: Icons.list_alt_rounded),
                  ]),
                  SizedBox(height: 20),
                ]) : SizedBox.shrink(),
              ),
              SizedBox(height: 20),
              Text('Consultas de hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MedColors.text)),
              SizedBox(height: 10),
              if (consultasHoje.isEmpty) _empty('Sem consultas hoje', '')
              else ...consultasHoje.map((c) => _cardConsulta(c, prov)),
            ]));
          })),
    ]);
  }

  Widget _tabConsultas(AuthProvider prov, String uid) {
    return Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Consultas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MedColors.text)),
        SizedBox(height: 12),
        MedField(hint: 'Pesquisar paciente...', controller: _txtPesquisa, prefix: Icon(Icons.search_rounded, color: MedColors.textHint, size: 20), onChanged: (v) => setState(() { _pesquisa = v; })),
        SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['todos','pendente','confirmada'].map((e) {
          bool sel = _filtroEstado == e;
          return GestureDetector(onTap: () => setState(() { _filtroEstado = e; }),
              child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: sel ? MedColors.teal : MedColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? MedColors.teal : MedColors.border)),
                  child: Text(e == 'todos' ? 'Todos' : labelEstado(e), style: TextStyle(fontSize: 12, color: sel ? Colors.white : MedColors.textSub, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
        }).toList())),
        SizedBox(height: 10),
        _filtroData(),
      ])),
      Expanded(child: StreamBuilder<List<Consulta>>(
          stream: _cs.consultasActivasMedico(uid),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: MedColors.teal));
            var lista = _filtrar(snap.data ?? []);
            if (lista.isEmpty) return _empty('Sem consultas', '');
            return ListView.builder(padding: EdgeInsets.symmetric(horizontal: 20), itemCount: lista.length,
                itemBuilder: (ctx, i) => _cardConsulta(lista[i], prov));
          })),
    ]);
  }

  Widget _tabHistorico(String uid) {
    return Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Histórico', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MedColors.text)),
        SizedBox(height: 12),
        MedField(hint: 'Pesquisar...', controller: _txtPesquisa, prefix: Icon(Icons.search_rounded, color: MedColors.textHint, size: 20), onChanged: (v) => setState(() { _pesquisa = v; })),
        SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['todos','realizada','cancelada'].map((e) {
          bool sel = _filtroEstado == e;
          return GestureDetector(onTap: () => setState(() { _filtroEstado = e; }),
              child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: sel ? MedColors.teal : MedColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? MedColors.teal : MedColors.border)),
                  child: Text(e == 'todos' ? 'Todos' : labelEstado(e), style: TextStyle(fontSize: 12, color: sel ? Colors.white : MedColors.textSub, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
        }).toList())),
        SizedBox(height: 10),
        _filtroData(),
      ])),
      Expanded(child: StreamBuilder<List<Consulta>>(
          stream: _cs.historicoMedico(uid),
          builder: (ctx, snap) {
            var lista = _filtrar(snap.data ?? []);
            if (lista.isEmpty) return _empty('Sem histórico', 'As consultas realizadas aparecerão aqui');
            return ListView.builder(padding: EdgeInsets.symmetric(horizontal: 20), itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  var c = lista[i];
                  return MedCard(child: Row(children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(color: corEstadoBg(c.estado), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.task_alt_rounded, color: corEstado(c.estado), size: 20)),
                    SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.pacienteNome, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MedColors.text)),
                      Text('${c.data}  ·  ${c.hora}', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                      if (c.diagnostico.isNotEmpty) Text(c.diagnostico, style: TextStyle(fontSize: 12, color: MedColors.textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    MedBadge(texto: labelEstado(c.estado), cor: corEstadoBg(c.estado), corTexto: corEstado(c.estado)),
                  ]));
                });
          })),
    ]);
  }

  Widget _tabPacientes(String uid) {
    return Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pacientes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MedColors.text)),
        SizedBox(height: 12),
        MedField(hint: 'Pesquisar paciente...', controller: _txtPesquisa, prefix: Icon(Icons.search_rounded, color: MedColors.textHint, size: 20), onChanged: (v) => setState(() { _pesquisa = v; })),
      ])),
      Expanded(child: FutureBuilder<List<Utilizador>>(
          future: _cs.buscarPacientesDoMedico(uid),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: MedColors.teal));
            var lista = (snap.data ?? []).where((p) => _pesquisa.isEmpty || p.nome.toLowerCase().contains(_pesquisa.toLowerCase())).toList();
            if (lista.isEmpty) return _empty('Sem pacientes', '');
            return ListView.builder(padding: EdgeInsets.symmetric(horizontal: 20), itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  var p = lista[i];
                  return MedCard(onTap: () => abrirProntuario(p), child: Row(children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: MedColors.accentLight, borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(p.nome[0].toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MedColors.accent)))),
                    SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.nome, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MedColors.text)),
                      Row(children: [
                        if (p.idade != null) Text('${p.idade} anos', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                        if (p.idade != null && p.telefone.isNotEmpty) Text('  ·  ', style: TextStyle(color: MedColors.textHint)),
                        if (p.telefone.isNotEmpty) Text(p.telefone, style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                      ]),
                    ])),
                    Icon(Icons.chevron_right_rounded, color: MedColors.textHint, size: 20),
                  ]));
                });
          })),
    ]);
  }

  Widget _tabPerfil(AuthProvider prov) {
    var u = prov.utilizador;
    var txtNome = TextEditingController(text: u?.nome ?? '');
    var txtTel = TextEditingController(text: u?.telefone ?? '');
    var txtEspec = TextEditingController(text: u?.especializacao ?? '');
    return SingleChildScrollView(padding: EdgeInsets.all(20), child: Column(children: [
      SizedBox(height: 10),
      Container(width: 80, height: 80, decoration: BoxDecoration(color: MedColors.tealLight, borderRadius: BorderRadius.circular(24)),
          child: Center(child: Text(u?.nome.isNotEmpty == true ? u!.nome[0].toUpperCase() : 'M',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: MedColors.teal)))),
      SizedBox(height: 16),
      Text(u?.nome ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      if (u?.especializacao != null) Text(u!.especializacao!, style: TextStyle(fontSize: 13, color: MedColors.teal, fontWeight: FontWeight.w600)),
      Text(u?.email ?? '', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
      SizedBox(height: 24),
      MedCard(child: Column(children: [
        _perfilRow(Icons.phone_outlined, 'Telemóvel', u?.telefone?.isEmpty == true ? 'Não definido' : (u?.telefone ?? '-')),
        Divider(height: 20, color: MedColors.border),
        _perfilRow(Icons.badge_outlined, 'Especialização', u?.especializacao ?? '-'),
      ])),
      SizedBox(height: 16),
      MedButton(label: 'Editar Perfil', onPressed: () => _sheet((ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sheetHandle(), SizedBox(height: 16),
        Text('Editar Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
        SizedBox(height: 20),
        sheetField(txtNome, 'Nome completo'),
        SizedBox(height: 10),
        sheetField(txtTel, 'Telemóvel', keyboard: TextInputType.phone),
        SizedBox(height: 10),
        sheetField(txtEspec, 'Especialização'),
        SizedBox(height: 20),
        MedButton(label: 'Guardar', onPressed: () async {
          await prov.editarPerfil(txtNome.text.trim(), txtTel.text.trim(), especializacao: txtEspec.text.trim());
          Navigator.pop(ctx); _snack('Perfil actualizado', MedColors.success);
        }, cor: MedColors.teal),
        SizedBox(height: 8),
      ])), cor: MedColors.teal),
      SizedBox(height: 12),
      MedButton(label: 'Terminar Sessão', onPressed: () => prov.logout(), cor: MedColors.danger),
    ]));
  }

  Widget _perfilRow(IconData icon, String label, String valor) => Row(children: [
    Icon(icon, color: MedColors.textSub, size: 18), SizedBox(width: 12),
    Text(label, style: TextStyle(fontSize: 14, color: MedColors.textSub)),
    Spacer(),
    Text(valor, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MedColors.text))]);

  Widget _cardConsulta(Consulta c, AuthProvider prov) {
    return MedCard(
        onTap: () => c.estado == 'confirmada' ? abrirPreencherConsulta(c, prov) : _abrirActualizarEstado(c),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: corEstadoBg(c.estado), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.person_rounded, color: corEstado(c.estado), size: 22)),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.pacienteNome, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MedColors.text)),
            Text('${c.data}  ·  ${c.hora}', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
            Text(c.motivo, style: TextStyle(fontSize: 12, color: MedColors.textSub)),
          ])),
          Column(children: [
            MedBadge(texto: labelEstado(c.estado), cor: corEstadoBg(c.estado), corTexto: corEstado(c.estado)),
            SizedBox(height: 6),
            Icon(c.estado == 'confirmada' ? Icons.edit_rounded : Icons.chevron_right_rounded, color: MedColors.textHint, size: 18),
          ]),
        ]));
  }

  void _abrirActualizarEstado(Consulta c) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isDismissible: true, enableDrag: true,
        builder: (_) => Container(padding: EdgeInsets.all(24),
            decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: MedColors.border, borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 20),
              Text('Actualizar Estado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MedColors.text)),
              Text('${c.pacienteNome}  ·  ${c.data}  ${c.hora}', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
              SizedBox(height: 24),
              Row(children: [
                Expanded(child: GestureDetector(onTap: () async {
                  await _cs.actualizarEstado(c.id, 'confirmada', pacienteId: c.pacienteId, medicoId: c.medicoId, pacienteNome: c.pacienteNome, medicoNome: c.medicoNome, data: c.data, hora: c.hora);
                  Navigator.pop(context);
                }, child: Container(padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: MedColors.successLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: MedColors.success.withOpacity(.3))),
                    child: Column(children: [Icon(Icons.check_circle_rounded, color: MedColors.success, size: 28), SizedBox(height: 6), Text('Confirmar', style: TextStyle(color: MedColors.success, fontWeight: FontWeight.w700))])))),
                SizedBox(width: 12),
                Expanded(child: GestureDetector(onTap: () async {
                  await _cs.actualizarEstado(c.id, 'cancelada', pacienteId: c.pacienteId, medicoId: c.medicoId, pacienteNome: c.pacienteNome, medicoNome: c.medicoNome, data: c.data, hora: c.hora);
                  Navigator.pop(context);
                }, child: Container(padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: MedColors.dangerLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: MedColors.danger.withOpacity(.3))),
                    child: Column(children: [Icon(Icons.cancel_rounded, color: MedColors.danger, size: 28), SizedBox(height: 6), Text('Cancelar', style: TextStyle(color: MedColors.danger, fontWeight: FontWeight.w700))])))),
              ]),
              SizedBox(height: 8),
            ])));
  }
}