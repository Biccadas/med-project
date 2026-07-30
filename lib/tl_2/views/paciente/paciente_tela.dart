import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/historico_service.dart';
import '../../repositories/consulta_repository.dart';
import '../../repositories/disponibilidade_repository.dart';
import '../../models/consulta.dart';
import '../../models/medicamento.dart';
import '../../models/utilizador.dart';
import '../../core/tema.dart';
import '../shared/chat_tela.dart';

class PacienteTela extends StatefulWidget {
  const PacienteTela({super.key});
  @override
  State<PacienteTela> createState() => _PacienteTelaState();
}

class _PacienteTelaState extends State<PacienteTela> {
  late final ConsultaRepository _cs;
  final _hs = HistoricoService();
  late final DisponibilidadeRepository _ds;
  int _tab = 0;
  String _filtroEstado = 'todos';
  String _pesquisa = '';
  DateTime? _dataInicio; DateTime? _dataFim;
  bool _kpiVisivel = true;
  final _scrollInicio = ScrollController();

  @override
  void initState() {
    super.initState();
    _cs = context.read<ConsultaRepository>();
    _ds = context.read<DisponibilidadeRepository>();
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

  void abrirMarcarConsulta() async {
    var medicos = await _cs.buscarMedicos();
    if (medicos.isEmpty) { _snack('Nenhum médico disponível', MedColors.warning); return; }
    var prov = Provider.of<AuthProvider>(context, listen: false);
    Utilizador? medicoSel; DateTime? dataSel; String? horaSel;
    List<String> horasDisp = []; bool carregandoHoras = false;
    var txtMotivo = TextEditingController(); String erro = '';
    final espec = medicos.map((m) => m.especializacao).whereType<String>().toSet().toList()..sort();
    String? filtroEspec;

    Future<void> carregarHoras(StateSetter setS, String medicoId, DateTime data) async {
      setS(() { carregandoHoras = true; horaSel = null; horasDisp = []; });
      var horas = await _ds.horasDisponiveis(medicoId, data.weekday - 1);
      setS(() { horasDisp = horas; carregandoHoras = false; });
    }

    _sheet(context, (ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sheetHandle(), SizedBox(height: 16),
      Text('Nova Consulta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      Text('Agende uma consulta médica', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
      SizedBox(height: 16),
      if (espec.isNotEmpty) ...[
        Text('Especialização', style: TextStyle(fontSize: 12, color: MedColors.textSub, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          GestureDetector(onTap: () => setS(() { filtroEspec = null; medicoSel = null; horaSel = null; horasDisp = []; }),
            child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: filtroEspec == null ? MedColors.accent : MedColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: filtroEspec == null ? MedColors.accent : MedColors.border)),
              child: Text('Todos', style: TextStyle(fontSize: 12, color: filtroEspec == null ? Colors.white : MedColors.textSub, fontWeight: filtroEspec == null ? FontWeight.w700 : FontWeight.w500)))),
          ...espec.map((e) => GestureDetector(onTap: () => setS(() { filtroEspec = e; medicoSel = null; horaSel = null; horasDisp = []; }),
            child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: filtroEspec == e ? MedColors.accent : MedColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: filtroEspec == e ? MedColors.accent : MedColors.border)),
              child: Text(e, style: TextStyle(fontSize: 12, color: filtroEspec == e ? Colors.white : MedColors.textSub, fontWeight: filtroEspec == e ? FontWeight.w700 : FontWeight.w500))))),
        ])),
        SizedBox(height: 10),
      ],
      sheetDropdown<Utilizador>('Seleccionar médico', medicoSel,
          medicos.where((m) => filtroEspec == null || m.especializacao == filtroEspec)
              .map((m) => DropdownMenuItem(value: m, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                  children: [Text(m.nome, style: TextStyle(fontWeight: FontWeight.w600)),
                    if (m.especializacao != null) Text(m.especializacao!, style: TextStyle(fontSize: 11, color: MedColors.textSub))]))).toList(),
          (v) { setS(() { medicoSel = v; horaSel = null; horasDisp = []; }); if (dataSel != null) carregarHoras(setS, v!.uid, dataSel!); }),
      SizedBox(height: 10),
      datePicker(ctx, dataSel, 'Seleccionar data', (d) { setS(() { dataSel = d; horaSel = null; }); if (medicoSel != null) carregarHoras(setS, medicoSel!.uid, d); }),
      if (medicoSel != null && dataSel != null) ...[
        SizedBox(height: 12),
        if (carregandoHoras)
          Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator(color: MedColors.accent, strokeWidth: 2)))
        else if (horasDisp.isEmpty)
          Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Médico sem disponibilidade neste dia', style: TextStyle(fontSize: 13, color: MedColors.warning, fontWeight: FontWeight.w500)))
        else ...[
          Text('Horário disponível', style: TextStyle(fontSize: 12, color: MedColors.textSub, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: horasDisp.map((h) {
            bool sel = horaSel == h;
            return GestureDetector(
              onTap: () => setS(() { horaSel = h; }),
              child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: sel ? MedColors.accent : MedColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? MedColors.accent : MedColors.border)),
                child: Text(h, style: TextStyle(fontSize: 12, color: sel ? Colors.white : MedColors.textSub, fontWeight: sel ? FontWeight.w700 : FontWeight.w400))),
            );
          }).toList()),
        ],
      ],
      SizedBox(height: 10),
      sheetField(txtMotivo, 'Motivo da consulta'),
      if (erro.isNotEmpty) ...[SizedBox(height: 8), Text(erro, style: TextStyle(color: MedColors.danger, fontSize: 12))],
      SizedBox(height: 20),
      MedButton(label: 'Agendar Consulta', onPressed: () async {
        if (medicoSel == null || dataSel == null || horaSel == null || txtMotivo.text.isEmpty) {
          setS(() { erro = 'Preencha todos os campos.'; }); return;
        }
        String dataStr = formatarData(dataSel!);
        await _cs.marcarConsulta(Consulta(id: '', pacienteId: prov.utilizador!.uid, pacienteNome: prov.utilizador!.nome,
            medicoId: medicoSel!.uid, medicoNome: medicoSel!.nome, medicoEspec: medicoSel!.especializacao ?? '',
            data: dataStr, hora: horaSel!, motivo: txtMotivo.text.trim(), estado: 'pendente'));
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Consulta marcada com sucesso!'), backgroundColor: MedColors.success));
        }
      }),
      SizedBox(height: 8),
    ]));
  }

  void abrirDetalheConsulta(Consulta c) {
    showModalBottomSheet(context: context, isScrollControlled: true, isDismissible: true, enableDrag: true, backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(initialChildSize: .75, maxChildSize: .95, minChildSize: .4,
            builder: (ctx, scroll) => Container(
              decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(children: [
                Padding(padding: EdgeInsets.fromLTRB(20, 14, 20, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: _handle()),
                  SizedBox(height: 14),
                  Row(children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(color: MedColors.accentLight, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.calendar_today_rounded, color: MedColors.accent, size: 20)),
                    SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Dr. ${c.medicoNome}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MedColors.text)),
                      Text('${c.data}  ·  ${c.hora}', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
                    ]),
                  ]),
                ])),
                Divider(height: 20, color: MedColors.border),
                Expanded(child: ListView(controller: scroll, padding: EdgeInsets.symmetric(horizontal: 20), children: [
                  _infoRow('Motivo', c.motivo),
                  if (c.diagnostico.isNotEmpty) ...[SizedBox(height: 10), _infoRow('Diagnóstico', c.diagnostico)],
                  if (c.observacoes.isNotEmpty) ...[SizedBox(height: 10), _infoRow('Observações', c.observacoes)],
                  if (c.exames.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text('Exames Pedidos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedColors.text)),
                    SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: c.exames.map((e) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: MedColors.accentLight, borderRadius: BorderRadius.circular(20)),
                        child: Text(e, style: TextStyle(fontSize: 12, color: MedColors.accent, fontWeight: FontWeight.w600)))).toList()),
                  ],
                  if (c.resultadosExames.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text('Resultados dos Exames', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedColors.text)),
                    SizedBox(height: 8),
                    ...c.resultadosExames.map((r) => Container(
                        margin: EdgeInsets.only(bottom: 6), padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(color: MedColors.tealLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: MedColors.teal.withOpacity(.2))),
                        child: Row(children: [Icon(Icons.science_outlined, color: MedColors.teal, size: 16), SizedBox(width: 8),
                          Expanded(child: Text(r, style: TextStyle(fontSize: 13, color: MedColors.text)))]))),
                  ],
                  SizedBox(height: 16),
                  Text('Medicação Prescrita', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MedColors.text)),
                  SizedBox(height: 10),
                  FutureBuilder<List<Medicamento>>(
                      future: _hs.medicamentosDaConsulta(c.id),
                      builder: (ctx, snap) {
                        var meds = snap.data ?? [];
                        if (meds.isEmpty) return Text('Nenhum medicamento prescrito', style: TextStyle(fontSize: 13, color: MedColors.textSub));
                        return Column(children: meds.map((m) => Container(
                            margin: EdgeInsets.only(bottom: 8), padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(color: MedColors.successLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.success.withOpacity(.2))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Icon(Icons.medication_rounded, color: MedColors.success, size: 18), SizedBox(width: 8),
                                Text(m.nome, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: MedColors.text))]),
                              SizedBox(height: 6),
                              Text('${m.dosagem}  ·  ${m.frequencia}', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                              Text('${m.dataInicio} → ${m.dataFim}', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                              SizedBox(height: 4),
                              Text('Prescrito por Dr. ${m.medicoNome}', style: TextStyle(fontSize: 11, color: MedColors.success, fontWeight: FontWeight.w600)),
                            ]))).toList());
                      }),
                  if (c.estado == 'pendente') ...[
                    SizedBox(height: 16),
                    MedButton(
                      label: 'Reagendar Consulta',
                      onPressed: () {
                        DateTime? novaData; String? novaHora;
                        List<String> horasDisp = []; bool carregando = false;
                        Future<void> carregar(StateSetter setS, DateTime data) async {
                          setS(() { carregando = true; novaHora = null; horasDisp = []; });
                          var horas = await _ds.horasDisponiveis(c.medicoId, data.weekday - 1);
                          setS(() { horasDisp = horas; carregando = false; });
                        }
                        _sheet(context, (ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sheetHandle(), SizedBox(height: 16),
                          Text('Reagendar Consulta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
                          Text('Dr. ${c.medicoNome}', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
                          SizedBox(height: 20),
                          datePicker(ctx, novaData, 'Nova data', (d) { setS(() { novaData = d; novaHora = null; }); carregar(setS, d); }),
                          if (novaData != null) ...[
                            SizedBox(height: 12),
                            if (carregando)
                              Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator(color: MedColors.accent, strokeWidth: 2)))
                            else if (horasDisp.isEmpty)
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Médico sem disponibilidade neste dia', style: TextStyle(fontSize: 13, color: MedColors.warning, fontWeight: FontWeight.w500)))
                            else ...[
                              Text('Horário disponível', style: TextStyle(fontSize: 12, color: MedColors.textSub, fontWeight: FontWeight.w600)),
                              SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: horasDisp.map((h) {
                                bool sel = novaHora == h;
                                return GestureDetector(onTap: () => setS(() { novaHora = h; }),
                                  child: Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: sel ? MedColors.accent : MedColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? MedColors.accent : MedColors.border)),
                                    child: Text(h, style: TextStyle(fontSize: 12, color: sel ? Colors.white : MedColors.textSub, fontWeight: sel ? FontWeight.w700 : FontWeight.w400))));
                              }).toList()),
                            ],
                          ],
                          SizedBox(height: 20),
                          MedButton(label: 'Confirmar', onPressed: () async {
                            if (novaData == null || novaHora == null) return;
                            await _cs.editarConsulta(c.id, formatarData(novaData!), novaHora!, c.motivo);
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                            _snack('Consulta reagendada', MedColors.success);
                          }),
                          SizedBox(height: 8),
                        ]));
                      },
                      cor: MedColors.accent,
                    ),
                    SizedBox(height: 8),
                    MedButton(
                      label: 'Cancelar Consulta',
                      onPressed: () {
                        showDialog(context: context, builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text('Cancelar consulta?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          content: Text('Tem a certeza que deseja cancelar esta consulta com Dr. ${c.medicoNome}?',
                              style: TextStyle(color: MedColors.textSub, fontSize: 14)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context),
                                child: Text('Não', style: TextStyle(color: MedColors.textSub))),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                var prov = Provider.of<AuthProvider>(context, listen: false);
                                await _cs.actualizarEstado(c.id, 'cancelada',
                                    pacienteId: prov.utilizador?.uid ?? '',
                                    medicoId: c.medicoId,
                                    pacienteNome: c.pacienteNome,
                                    medicoNome: c.medicoNome,
                                    data: c.data, hora: c.hora);
                                _snack('Consulta cancelada', MedColors.danger);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: MedColors.danger, foregroundColor: Colors.white,
                                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ));
                      },
                      cor: MedColors.danger,
                    ),
                  ],
                  SizedBox(height: 16),
                  MedButton(
                    label: 'Chat com Dr. ${c.medicoNome.split(' ').first}',
                    onPressed: () {
                      final prov = Provider.of<AuthProvider>(context, listen: false);
                      final uid = prov.utilizador?.uid ?? '';
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatTela(
                        meuId: uid, meuNome: prov.utilizador?.nome ?? '', outroId: c.medicoId, outroNome: 'Dr. ${c.medicoNome}',
                      )));
                    },
                    cor: MedColors.teal,
                  ),
                  SizedBox(height: 24),
                ])),
              ]),
            )));
  }

  void abrirEditarPerfil(AuthProvider prov) {
    var txtNome = TextEditingController(text: prov.utilizador?.nome ?? '');
    var txtTel = TextEditingController(text: prov.utilizador?.telefone ?? '');
    _sheet(context, (ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sheetHandle(), SizedBox(height: 16),
      Text('Editar Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      SizedBox(height: 20),
      sheetField(txtNome, 'Nome completo'),
      SizedBox(height: 10),
      sheetField(txtTel, 'Telemóvel', keyboard: TextInputType.phone),
      SizedBox(height: 20),
      MedButton(label: 'Guardar', onPressed: () async {
        await prov.editarPerfil(txtNome.text.trim(), txtTel.text.trim());
        Navigator.pop(ctx);
        _snack('Perfil actualizado', MedColors.success);
      }),
      SizedBox(height: 8),
    ]));
  }

  void _sheet(BuildContext context, Widget Function(BuildContext, StateSetter) builder) {
    showModalBottomSheet(context: context, isScrollControlled: true, isDismissible: true, enableDrag: true, backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Padding(padding: EdgeInsets.all(24), child: builder(ctx, setS)))));
  }
  void _snack(String msg, Color cor) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
  Widget _handle() => Container(width: 40, height: 4, decoration: BoxDecoration(color: MedColors.border, borderRadius: BorderRadius.circular(2)));
  Widget _sheetHandle() => Center(child: _handle());
  Widget _infoRow(String l, String v) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('$l:  ', style: TextStyle(fontSize: 13, color: MedColors.textSub, fontWeight: FontWeight.w600)),
    Expanded(child: Text(v, style: TextStyle(fontSize: 13, color: MedColors.text, fontWeight: FontWeight.w500)))]);

  List<Consulta> _filtrar(List<Consulta> lista) {
    var r = lista;
    if (_filtroEstado != 'todos') r = r.where((c) => c.estado == _filtroEstado).toList();
    if (_pesquisa.isNotEmpty) r = r.where((c) => c.medicoNome.toLowerCase().contains(_pesquisa.toLowerCase()) || c.motivo.toLowerCase().contains(_pesquisa.toLowerCase())).toList();
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

    return Scaffold(
      backgroundColor: MedColors.bg,
      body: SafeArea(child: _buildTab(prov, uid, primeiro)),
      floatingActionButton: _tab == 1 ? Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: MedShadow.button),
          child: FloatingActionButton(onPressed: abrirMarcarConsulta, backgroundColor: MedColors.accent, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Icon(Icons.add_rounded, size: 26))) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(color: MedColors.navBg, borderRadius: BorderRadius.circular(24), boxShadow: MedShadow.nav, border: Border.all(color: MedColors.border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navItem(0, Icons.home_rounded, 'Início'),
          _navItem(1, Icons.calendar_today_rounded, 'Consultas'),
          _navItem(2, Icons.history_rounded, 'Histórico'),
          _navItem(3, Icons.medication_rounded, 'Medicamentos'),
          _navItem(4, Icons.person_rounded, 'Perfil'),
        ]),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool sel = _tab == index;
    return GestureDetector(
      onTap: () => setState(() { _tab = index; _filtroEstado = 'todos'; _pesquisa = ''; _txtPesquisa.clear(); _dataInicio = null; _dataFim = null; _kpiVisivel = true; }),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.transparent),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: sel ? MedColors.accent : MedColors.textHint, size: 22),
          SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: sel ? MedColors.accent : MedColors.textHint, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _buildTab(AuthProvider prov, String uid, String primeiro) {
    switch (_tab) {
      case 0: return _tabInicio(prov, uid, primeiro);
      case 1: return _tabConsultas(uid);
      case 2: return _tabHistorico(uid);
      case 3: return _tabMedicamentos(uid);
      case 4: return _tabPerfil(prov);
      default: return _tabInicio(prov, uid, primeiro);
    }
  }

  Widget _tabInicio(AuthProvider prov, String uid, String primeiro) {
    String hoje = formatarData(DateTime.now());
    return Column(children: [
      _header(prov, uid, primeiro),
      Expanded(child: SingleChildScrollView(controller: _scrollInicio, padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedSize(
          duration: Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: _kpiVisivel ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Resumo de hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MedColors.text)),
            SizedBox(height: 12),
            StreamBuilder<List<Consulta>>(
                stream: _cs.consultasActivasPaciente(uid),
                builder: (ctx, snap) {
                  var lista = snap.data ?? [];
                  var consultasHoje = lista.where((c) => c.data == hoje).toList();
                  var pendentes = lista.where((c) => c.estado == 'pendente').length;
                  var confirmadas = consultasHoje.where((c) => c.estado == 'confirmada').length;
                  return Column(children: [
                    Row(children: [
                      MedKpiCard(label: 'Consultas hoje', valor: '${consultasHoje.length}', cor: MedColors.accent, bgCor: MedColors.accentLight, icon: Icons.today_rounded),
                      SizedBox(width: 10),
                      MedKpiCard(label: 'Confirmadas hoje', valor: '$confirmadas', cor: MedColors.success, bgCor: MedColors.successLight, icon: Icons.check_circle_outline_rounded),
                    ]),
                    SizedBox(height: 10),
                    Row(children: [
                      MedKpiCard(label: 'Pendentes', valor: '$pendentes', cor: MedColors.warning, bgCor: MedColors.warningLight, icon: Icons.pending_outlined),
                      SizedBox(width: 10),
                      MedKpiCard(label: 'Total activas', valor: '${lista.length}', cor: MedColors.teal, bgCor: MedColors.tealLight, icon: Icons.list_alt_rounded),
                    ]),
                  ]);
                }),
            SizedBox(height: 20),
          ]) : SizedBox.shrink(),
        ),
        SizedBox(height: 20),
        Text('Próximas consultas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MedColors.text)),
        SizedBox(height: 10),
        StreamBuilder<List<Consulta>>(
            stream: _cs.consultasActivasPaciente(uid),
            builder: (ctx, snap) {
              var lista = (snap.data ?? []).where((c) => c.estado == 'confirmada').take(3).toList();
              if (lista.isEmpty) return _empty('Sem consultas confirmadas', '');
              return Column(children: lista.map((c) => _cardConsulta(c)).toList());
            }),
      ]))),
    ]);
  }

  Widget _header(AuthProvider prov, String uid, String primeiro) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Olá, $primeiro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MedColors.text, letterSpacing: -.3)),
          Text('Como se sente hoje?', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
        ])),
        AvisosBadge(stream: _cs.avisosNaoLidos(uid), onTap: () {
          mostrarAvisos(context, _cs.todosAvisos(uid), _cs, uid, onTapAviso: (aviso) {
          if (aviso.tipo == 'mensagem' && aviso.consultaId.isNotEmpty) {
            var prov = Provider.of<AuthProvider>(context, listen: false);
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatTela(
              meuId: uid,
              meuNome: prov.utilizador?.nome ?? '',
              outroId: aviso.consultaId,
              outroNome: aviso.titulo.replaceFirst('Nova mensagem de ', ''),
            )));
          }
        });
        }),
        SizedBox(width: 8),
        GestureDetector(onTap: () => prov.logout(),
            child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border), boxShadow: MedShadow.card),
                child: Icon(Icons.logout_rounded, color: MedColors.textSub, size: 18))),
      ]),
    );
  }

  Widget _tabConsultas(String uid) {
    return Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Consultas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MedColors.text)),
        SizedBox(height: 12),
        MedField(hint: 'Pesquisar por médico ou motivo...', controller: _txtPesquisa,
            prefix: Icon(Icons.search_rounded, color: MedColors.textHint, size: 20),
            onChanged: (v) => setState(() { _pesquisa = v; })),
        SizedBox(height: 10),
        _filtroChips(['todos', 'pendente', 'confirmada']),
        SizedBox(height: 10),
        _filtroData(),
      ])),
      Expanded(child: StreamBuilder<List<Consulta>>(
          stream: _cs.consultasActivasPaciente(uid),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: MedColors.accent));
            var lista = _filtrar(snap.data ?? []);
            if (lista.isEmpty) return _empty('Nenhuma consulta', 'Toque em + para marcar uma consulta');
            return ListView.builder(padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: lista.length, itemBuilder: (ctx, i) => _cardConsulta(lista[i]));
          })),
    ]);
  }

  Widget _tabHistorico(String uid) {
    return Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Histórico', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MedColors.text)),
        SizedBox(height: 12),
        MedField(hint: 'Pesquisar...', controller: _txtPesquisa,
            prefix: Icon(Icons.search_rounded, color: MedColors.textHint, size: 20),
            onChanged: (v) => setState(() { _pesquisa = v; })),
        SizedBox(height: 10),
        _filtroChips(['todos', 'realizada', 'cancelada']),
        SizedBox(height: 10),
        _filtroData(),
      ])),
      Expanded(child: StreamBuilder<List<Consulta>>(
          stream: _cs.historicoPaciente(uid),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: MedColors.accent));
            var lista = _filtrar(snap.data ?? []);
            if (lista.isEmpty) return _empty('Sem histórico', 'As consultas realizadas aparecerão aqui');
            return ListView.builder(padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: lista.length, itemBuilder: (ctx, i) => _cardConsulta(lista[i]));
          })),
    ]);
  }

  Widget _tabMedicamentos(String uid) {
    return Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Medicamentos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MedColors.text)),
        SizedBox(height: 12),
        MedField(hint: 'Pesquisar medicamento...', controller: _txtPesquisa,
            prefix: Icon(Icons.search_rounded, color: MedColors.textHint, size: 20),
            onChanged: (v) => setState(() { _pesquisa = v; })),
      ])),
      Expanded(child: StreamBuilder<List<Medicamento>>(
          stream: _hs.medicamentosDoPaciente(uid),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: MedColors.accent));
            var lista = (snap.data ?? []).where((m) => _pesquisa.isEmpty || m.nome.toLowerCase().contains(_pesquisa.toLowerCase())).toList();
            if (lista.isEmpty) return _empty('Sem medicamentos', 'Os medicamentos prescritos aparecerão aqui');
            return ListView.builder(padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: lista.length, itemBuilder: (ctx, i) {
                  var m = lista[i];
                  return MedCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 46, height: 46, decoration: BoxDecoration(color: MedColors.successLight, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.medication_rounded, color: MedColors.success, size: 22)),
                      SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.nome, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MedColors.text)),
                        Text('${m.dosagem}  ·  ${m.frequencia}', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                      ])),
                    ]),
                    SizedBox(height: 10), Container(height: 1, color: MedColors.border), SizedBox(height: 10),
                    Row(children: [
                      Icon(Icons.person_outline_rounded, size: 13, color: MedColors.textSub), SizedBox(width: 4),
                      Text('Dr. ${m.medicoNome}', style: TextStyle(fontSize: 12, color: MedColors.textSub, fontWeight: FontWeight.w500)),
                      Spacer(),
                      Icon(Icons.calendar_today_rounded, size: 13, color: MedColors.textSub), SizedBox(width: 4),
                      Text('${m.dataInicio} → ${m.dataFim}', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                    ]),
                  ]));
                });
          })),
    ]);
  }

  Widget _tabPerfil(AuthProvider prov) {
    var u = prov.utilizador;
    return SingleChildScrollView(padding: EdgeInsets.all(20), child: Column(children: [
      SizedBox(height: 10),
      Container(width: 80, height: 80, decoration: BoxDecoration(color: MedColors.accentLight, borderRadius: BorderRadius.circular(24)),
          child: Center(child: Text(u?.nome.isNotEmpty == true ? u!.nome[0].toUpperCase() : 'P',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: MedColors.accent)))),
      SizedBox(height: 16),
      Text(u?.nome ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      Text(u?.email ?? '', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
      SizedBox(height: 24),
      MedCard(child: Column(children: [
        _perfilRow(Icons.phone_outlined, 'Telemóvel', u?.telefone?.isEmpty == true ? 'Não definido' : (u?.telefone ?? '-')),
        Divider(height: 20, color: MedColors.border),
        _perfilRow(Icons.cake_outlined, 'Idade', u?.idade != null ? '${u!.idade} anos' : 'Não definida'),
        Divider(height: 20, color: MedColors.border),
        _perfilRow(Icons.badge_outlined, 'Tipo de conta', 'Paciente'),
      ])),
      SizedBox(height: 16),
      MedButton(label: 'Editar Perfil', onPressed: () => abrirEditarPerfil(prov), cor: MedColors.accent),
      SizedBox(height: 12),
      MedButton(label: 'Terminar Sessão', onPressed: () => prov.logout(), cor: MedColors.danger),
      SizedBox(height: 16),
      // TEMPORÁRIO: remover antes de produção — acesso ao design preview
      TextButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/design'),
        icon: Icon(Icons.construction_rounded, size: 16, color: MedColors.textSub),
        label: Text('Ver Design (temporário)', style: TextStyle(fontSize: 12, color: MedColors.textSub, fontWeight: FontWeight.w600)),
      ),
    ]));
  }

  Widget _perfilRow(IconData icon, String label, String valor) {
    return Row(children: [
      Icon(icon, color: MedColors.textSub, size: 18), SizedBox(width: 12),
      Text(label, style: TextStyle(fontSize: 14, color: MedColors.textSub)),
      Spacer(),
      Text(valor, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MedColors.text)),
    ]);
  }

  Widget _filtroChips(List<String> estados) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: estados.map((e) {
      bool sel = _filtroEstado == e;
      String label = e == 'todos' ? 'Todos' : labelEstado(e);
      return GestureDetector(
          onTap: () => setState(() { _filtroEstado = e; }),
          child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: sel ? MedColors.accent : MedColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? MedColors.accent : MedColors.border)),
              child: Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.white : MedColors.textSub, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
    }).toList()));
  }

  Widget _cardConsulta(Consulta c) {
    return MedCard(
        onTap: () => abrirDetalheConsulta(c),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: corEstadoBg(c.estado), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.calendar_today_rounded, color: corEstado(c.estado), size: 20)),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dr. ${c.medicoNome}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MedColors.text)),
            SizedBox(height: 3),
            Text('${c.data}  ·  ${c.hora}', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
            Text(c.motivo, style: TextStyle(fontSize: 12, color: MedColors.textSub)),
          ])),
          Column(children: [
            MedBadge(texto: labelEstado(c.estado), cor: corEstadoBg(c.estado), corTexto: corEstado(c.estado)),
            SizedBox(height: 6), Icon(Icons.chevron_right_rounded, color: MedColors.textHint, size: 18),
          ]),
        ]));
  }

  Widget _empty(String t, String s) => Center(child: Padding(padding: EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 64, height: 64, decoration: BoxDecoration(color: MedColors.accentLight, borderRadius: BorderRadius.circular(18)),
        child: Icon(Icons.inbox_rounded, color: MedColors.accent, size: 28)),
    SizedBox(height: 16),
    Text(t, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: MedColors.text)),
    if (s.isNotEmpty) ...[SizedBox(height: 6), Text(s, style: TextStyle(fontSize: 13, color: MedColors.textSub), textAlign: TextAlign.center)],
  ])));
}