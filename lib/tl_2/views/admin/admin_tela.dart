import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/utilizador_service.dart';
import '../../services/consulta_service.dart';
import '../../services/auth_service.dart';
import '../../models/utilizador.dart';
import '../../models/consulta.dart';
import '../../core/tema.dart';
import '../shared/chat_tela.dart';

class AdminTela extends StatefulWidget {
  const AdminTela({super.key});
  @override
  State<AdminTela> createState() => _AdminTelaState();
}

class _AdminTelaState extends State<AdminTela> {
  final _us = UtilizadorService();
  final _cs = ConsultaService();
  final _auth = AuthService();
  int _tab = 0;

  static const _especializacoes = [
    'Clínica Geral', 'Cardiologia', 'Dermatologia', 'Cirurgia',
    'Pediatria', 'Ginecologia', 'Ortopedia', 'Neurologia',
    'Oftalmologia', 'Psiquiatria', 'Oncologia', 'Urologia',
  ];
  String _pesquisa = '';
  String _filtroEstado = 'todos';
  final _txtPesquisa = TextEditingController();
  DateTime? _dataInicio; DateTime? _dataFim;
  bool _kpiVisivel = true;

  void _sheet(Widget Function(BuildContext, StateSetter) builder) {
    showModalBottomSheet(context: context, isScrollControlled: true, isDismissible: true, enableDrag: true, backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Padding(padding: EdgeInsets.all(24), child: builder(ctx, setS)))));
  }
  void _snack(String msg, Color cor) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
  Widget _handle() => Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: MedColors.border, borderRadius: BorderRadius.circular(2))));

  void abrirCriarConsulta() async {
    var medicos = await _cs.buscarMedicos();
    var pacientes = await _cs.buscarPacientes();
    if (medicos.isEmpty || pacientes.isEmpty) { _snack('Precisa de médicos e pacientes', MedColors.warning); return; }
    Utilizador? medicoSel; Utilizador? pacSel; DateTime? dataSel; TimeOfDay? horaSel; var txtMotivo = TextEditingController(); String estado = 'pendente'; String erro = '';
    _sheet((ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _handle(), SizedBox(height: 16),
      Text('Nova Consulta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      SizedBox(height: 20),
      sheetDropdown<Utilizador>('Paciente', pacSel, pacientes.map((p) => DropdownMenuItem(value: p, child: Text(p.nome))).toList(), (v) => setS(() { pacSel = v; })),
      SizedBox(height: 10),
      sheetDropdown<Utilizador>('Médico', medicoSel, medicos.map((m) => DropdownMenuItem(value: m, child: Text(m.nome))).toList(), (v) => setS(() { medicoSel = v; })),
      SizedBox(height: 10),
      datePicker(ctx, dataSel, 'Data', (d) => setS(() { dataSel = d; })),
      SizedBox(height: 10),
      timePicker(ctx, horaSel, 'Seleccionar hora', (h) => setS(() { horaSel = h; })),
      SizedBox(height: 10),
      sheetField(txtMotivo, 'Motivo'),
      SizedBox(height: 10),
      sheetDropdown<String>('Estado', estado, ['pendente','confirmada','cancelada'].map((e) => DropdownMenuItem(value: e, child: Text(labelEstado(e)))).toList(), (v) => setS(() { estado = v!; })),
      if (erro.isNotEmpty) ...[SizedBox(height: 8), Text(erro, style: TextStyle(color: MedColors.danger, fontSize: 12))],
      SizedBox(height: 20),
      MedButton(label: 'Criar Consulta', onPressed: () async {
        if (pacSel == null || medicoSel == null || dataSel == null || horaSel == null) { setS(() { erro = 'Preencha todos os campos.'; }); return; }
        String dataStr = formatarData(dataSel!);
        await _cs.marcarConsulta(Consulta(id: '', pacienteId: pacSel!.uid, pacienteNome: pacSel!.nome,
            medicoId: medicoSel!.uid, medicoNome: medicoSel!.nome, medicoEspec: medicoSel!.especializacao ?? '',
            data: dataStr, hora: '${horaSel!.hour.toString().padLeft(2, '0')}:${horaSel!.minute.toString().padLeft(2, '0')}', motivo: txtMotivo.text.trim(), estado: estado));
        Navigator.pop(ctx); _snack('Consulta criada', MedColors.success);
      }, cor: MedColors.purple),
      SizedBox(height: 8),
    ]));
  }

  void abrirEditarConsulta(Consulta c) {
    var txtData = TextEditingController(text: c.data);
    var txtHora = TextEditingController(text: c.hora);
    var txtMotivo = TextEditingController(text: c.motivo);
    String estado = c.estado;
    _sheet((ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _handle(), SizedBox(height: 16),
      Text('Editar Consulta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      Text('${c.pacienteNome}  ·  Dr. ${c.medicoNome}', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
      SizedBox(height: 20),
      sheetField(txtData, 'Data'),
      SizedBox(height: 10),
      sheetField(txtHora, 'Hora'),
      SizedBox(height: 10),
      sheetField(txtMotivo, 'Motivo'),
      SizedBox(height: 10),
      sheetDropdown<String>('Estado', estado, ['pendente','confirmada','cancelada','realizada'].map((e) => DropdownMenuItem(value: e, child: Text(labelEstado(e)))).toList(), (v) => setS(() { estado = v!; })),
      SizedBox(height: 20),
      MedButton(label: 'Guardar', onPressed: () async {
        await _cs.editarConsulta(c.id, txtData.text.trim(), txtHora.text.trim(), txtMotivo.text.trim());
        if (estado != c.estado) await _cs.actualizarEstado(c.id, estado, pacienteId: c.pacienteId, medicoId: c.medicoId, pacienteNome: c.pacienteNome, medicoNome: c.medicoNome, data: c.data, hora: c.hora);
        Navigator.pop(ctx); _snack('Consulta actualizada', MedColors.success);
      }, cor: MedColors.purple),
      SizedBox(height: 8),
    ]));
  }

  void confirmarEliminar(Consulta c) {
    showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar consulta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Eliminar consulta de ${c.pacienteNome}?', style: TextStyle(color: MedColors.textSub)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: MedColors.textSub))),
          ElevatedButton(onPressed: () async { await _cs.eliminarConsulta(c.id); Navigator.pop(context); _snack('Consulta eliminada', MedColors.danger); },
              style: ElevatedButton.styleFrom(backgroundColor: MedColors.danger, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w700))),
        ]));
  }

  void editarTipo(Utilizador u) {
    String tipoSel = u.tipo;
    _sheet((ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _handle(), SizedBox(height: 16),
      Text('Editar perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MedColors.text)),
      Text(u.nome, style: TextStyle(fontSize: 13, color: MedColors.textSub)),
      SizedBox(height: 20),
      ...['paciente', 'medico', 'admin'].map((tipo) {
        bool sel = tipoSel == tipo;
        Map<String, dynamic> info = {
          'paciente': {'icon': Icons.person_rounded, 'cor': MedColors.accent, 'bg': MedColors.accentLight, 'label': 'Paciente'},
          'medico': {'icon': Icons.medical_services_rounded, 'cor': MedColors.teal, 'bg': MedColors.tealLight, 'label': 'Médico'},
          'admin': {'icon': Icons.admin_panel_settings_rounded, 'cor': MedColors.purple, 'bg': MedColors.purpleLight, 'label': 'Administrador'},
        }[tipo]!;
        return GestureDetector(onTap: () => setS(() { tipoSel = tipo; }),
            child: AnimatedContainer(duration: Duration(milliseconds: 150), margin: EdgeInsets.only(bottom: 10), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: sel ? info['bg'] : MedColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? (info['cor'] as Color).withOpacity(.4) : MedColors.border, width: sel ? 1.5 : 1)),
                child: Row(children: [
                  Icon(info['icon'] as IconData, color: sel ? info['cor'] as Color : MedColors.textSub, size: 20), SizedBox(width: 12),
                  Text(info['label'] as String, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? info['cor'] as Color : MedColors.text, fontSize: 15)),
                  Spacer(), if (sel) Icon(Icons.check_circle_rounded, color: info['cor'] as Color, size: 20),
                ])));
      }),
      SizedBox(height: 16),
      MedButton(label: 'Guardar', onPressed: () async { await _us.actualizarTipo(u.uid, tipoSel); Navigator.pop(ctx); }, cor: MedColors.purple),
      SizedBox(height: 8),
    ]));
  }

  void confirmarRemoverUser(Utilizador u) {
    showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remover utilizador', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Remover ${u.nome}?', style: TextStyle(color: MedColors.textSub)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: MedColors.textSub))),
          ElevatedButton(onPressed: () async { await _us.removerUtilizador(u.uid); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: MedColors.danger, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Remover', style: TextStyle(fontWeight: FontWeight.w700))),
        ]));
  }

  void _verDetalheUtilizador(Utilizador u, String adminUid, String adminNome) {
    final info = _tipoInfo(u.tipo);
    showModalBottomSheet(context: context, isScrollControlled: true, isDismissible: true, enableDrag: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: MedColors.border, borderRadius: BorderRadius.circular(2)))),
          SizedBox(height: 20),
          Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: info['bg'] as Color, borderRadius: BorderRadius.circular(14)),
                child: Icon(info['icon'] as IconData, color: info['cor'] as Color, size: 24)),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.nome, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MedColors.text)),
              Text(u.tipo[0].toUpperCase() + u.tipo.substring(1), style: TextStyle(fontSize: 13, color: info['cor'] as Color, fontWeight: FontWeight.w600)),
            ])),
          ]),
          SizedBox(height: 20),
          _detalheRow(Icons.mail_outline_rounded, u.email),
          if (u.telefone.isNotEmpty) ...[SizedBox(height: 8), _detalheRow(Icons.phone_outlined, u.telefone)],
          if (u.idade != null) ...[SizedBox(height: 8), _detalheRow(Icons.cake_outlined, '${u.idade} anos')],
          if (u.especializacao != null) ...[SizedBox(height: 8), _detalheRow(Icons.medical_services_outlined, u.especializacao!)],
          SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(ctx); editarTipo(u); },
              icon: Icon(Icons.edit_rounded, size: 16), label: Text('Editar tipo'),
              style: OutlinedButton.styleFrom(foregroundColor: MedColors.purple, side: BorderSide(color: MedColors.purple), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )),
            SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatTela(
                  meuId: adminUid, meuNome: adminNome, outroId: u.uid, outroNome: u.nome,
                )));
              },
              icon: Icon(Icons.chat_rounded, size: 16), label: Text('Mensagem'),
              style: OutlinedButton.styleFrom(foregroundColor: MedColors.teal, side: BorderSide(color: MedColors.teal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )),
          ]),
          SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () { Navigator.pop(ctx); confirmarRemoverUser(u); },
            icon: Icon(Icons.delete_outline_rounded, size: 16), label: Text('Remover utilizador'),
            style: OutlinedButton.styleFrom(foregroundColor: MedColors.danger, side: BorderSide(color: MedColors.danger), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
        ]),
      ));
  }

  Widget _detalheRow(IconData icon, String valor) {
    return Row(children: [
      Icon(icon, size: 16, color: MedColors.textSub),
      SizedBox(width: 10),
      Expanded(child: Text(valor, style: TextStyle(fontSize: 14, color: MedColors.text, fontWeight: FontWeight.w500))),
    ]);
  }

  void _abrirCriarMedico() {
    var txtNome = TextEditingController();
    var txtEmail = TextEditingController();
    var txtSenha = TextEditingController();
    var txtTel = TextEditingController();
    String? especSel; String erro = '';
    _sheet((ctx, setS) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _handle(), SizedBox(height: 16),
      Text('Adicionar Médico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text)),
      Text('Conta criada sem afectar a sessão actual', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
      SizedBox(height: 20),
      sheetField(txtNome, 'Nome completo'),
      SizedBox(height: 8),
      sheetField(txtEmail, 'Email', keyboard: TextInputType.emailAddress),
      SizedBox(height: 8),
      sheetField(txtSenha, 'Senha (mín. 6 caracteres)'),
      SizedBox(height: 8),
      sheetField(txtTel, 'Telemóvel', keyboard: TextInputType.phone),
      SizedBox(height: 8),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: MedColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border, width: 1.5)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Especialização', style: TextStyle(color: MedColors.textHint, fontSize: 13)),
          value: especSel,
          items: _especializacoes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setS(() { especSel = v; }),
        )),
      ),
      if (erro.isNotEmpty) ...[SizedBox(height: 8), Text(erro, style: TextStyle(color: MedColors.danger, fontSize: 12))],
      SizedBox(height: 20),
      MedButton(label: 'Criar Conta Médico', onPressed: () async {
        if (txtNome.text.isEmpty || txtEmail.text.isEmpty || txtSenha.text.isEmpty || txtTel.text.isEmpty || especSel == null) {
          setS(() { erro = 'Preencha todos os campos.'; }); return;
        }
        if (txtSenha.text.length < 6) { setS(() { erro = 'Senha com mínimo 6 caracteres.'; }); return; }
        var resultado = await _auth.registarMedico(
            txtNome.text.trim(), txtEmail.text.trim(), txtSenha.text.trim(), txtTel.text.trim(), especSel!);
        if (resultado != null) { setS(() { erro = 'Erro: $resultado'; }); return; }
        Navigator.pop(ctx);
        _snack('Médico criado com sucesso', MedColors.success);
      }, cor: MedColors.teal),
      SizedBox(height: 8),
    ]));
  }

  Map<String, dynamic> _tipoInfo(String tipo) {
    if (tipo == 'admin') return {'cor': MedColors.purple, 'bg': MedColors.purpleLight, 'icon': Icons.admin_panel_settings_rounded};
    if (tipo == 'medico') return {'cor': MedColors.teal, 'bg': MedColors.tealLight, 'icon': Icons.medical_services_rounded};
    return {'cor': MedColors.accent, 'bg': MedColors.accentLight, 'icon': Icons.person_rounded};
  }

  List<Consulta> _filtrarConsultas(List<Consulta> lista) {
    var r = lista;
    if (_filtroEstado != 'todos') r = r.where((c) => c.estado == _filtroEstado).toList();
    if (_pesquisa.isNotEmpty) r = r.where((c) =>
        c.pacienteNome.toLowerCase().contains(_pesquisa.toLowerCase()) ||
        c.medicoNome.toLowerCase().contains(_pesquisa.toLowerCase())).toList();
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

    return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: MedColors.bg,
          body: SafeArea(child: Column(children: [

            Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 0), child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: MedColors.purpleLight, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.admin_panel_settings_rounded, color: MedColors.purple, size: 20)),
              SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Administração', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MedColors.text, letterSpacing: -.3)),
                Text('Painel de controlo', style: TextStyle(fontSize: 12, color: MedColors.textSub)),
              ])),
              AvisosBadge(stream: _cs.avisosNaoLidos(uid), onTap: () => mostrarAvisos(context, _cs.todosAvisos(uid), _cs, uid,
                  onTapAviso: (aviso) {
                    if (aviso.tipo == 'mensagem' && aviso.consultaId.isNotEmpty) {
                      final adminNome = prov.utilizador?.nome ?? '';
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatTela(
                        meuId: uid, meuNome: adminNome, outroId: aviso.consultaId,
                        outroNome: aviso.titulo.replaceFirst('Nova mensagem de ', ''),
                      )));
                    }
                  })),
              SizedBox(width: 8),
              GestureDetector(onTap: () => prov.logout(),
                  child: Container(width: 40, height: 40, decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border), boxShadow: MedShadow.card),
                      child: Icon(Icons.logout_rounded, color: MedColors.textSub, size: 18))),
            ])),

            AnimatedSize(
              duration: Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _kpiVisivel ? Column(children: [
                SizedBox(height: 16),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: StreamBuilder<List<Utilizador>>(
                    stream: _us.todosUtilizadores(),
                    builder: (ctx, snap) {
                      var lista = snap.data ?? [];
                      return Row(children: [
                        MedKpiCard(label: 'Total', valor: '${lista.length}', cor: MedColors.text, bgCor: MedColors.surface, icon: Icons.people_rounded),
                        SizedBox(width: 10),
                        MedKpiCard(label: 'Médicos', valor: '${lista.where((u) => u.tipo == 'medico').length}', cor: MedColors.teal, bgCor: MedColors.tealLight, icon: Icons.medical_services_rounded),
                        SizedBox(width: 10),
                        MedKpiCard(label: 'Pacientes', valor: '${lista.where((u) => u.tipo == 'paciente').length}', cor: MedColors.accent, bgCor: MedColors.accentLight, icon: Icons.person_rounded),
                      ]);
                    })),
                SizedBox(height: 10),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: StreamBuilder<List<Consulta>>(
                    stream: _cs.todasConsultas(),
                    builder: (ctx, snap) {
                      var lista = snap.data ?? [];
                      return Row(children: [
                        MedKpiCard(label: 'Consultas', valor: '${lista.length}', cor: MedColors.purple, bgCor: MedColors.purpleLight, icon: Icons.calendar_today_rounded),
                        SizedBox(width: 10),
                        MedKpiCard(label: 'Confirmadas', valor: '${lista.where((c) => c.estado == 'confirmada').length}', cor: MedColors.teal, bgCor: MedColors.tealLight, icon: Icons.check_circle_outline_rounded),
                        SizedBox(width: 10),
                        MedKpiCard(label: 'Pendentes', valor: '${lista.where((c) => c.estado == 'pendente').length}', cor: MedColors.warning, bgCor: MedColors.warningLight, icon: Icons.pending_outlined),
                      ]);
                    })),
                SizedBox(height: 16),
              ]) : SizedBox.shrink(),
            ),

            Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: TabBar(
              indicator: UnderlineTabIndicator(borderSide: BorderSide(color: MedColors.purple, width: 2.5), insets: EdgeInsets.symmetric(horizontal: 8)),
              labelColor: MedColors.purple, unselectedLabelColor: MedColors.textSub,
              labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              dividerColor: Colors.transparent,
              onTap: (i) => setState(() { _tab = i; _filtroEstado = 'todos'; _pesquisa = ''; _txtPesquisa.clear(); }),
              tabs: [Tab(text: 'Utilizadores'), Tab(text: 'Consultas'), Tab(text: 'Relatório')],
            )),

            SizedBox(height: 12),

            Expanded(child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (n) {
                final esconder = n.metrics.pixels > 60;
                if (esconder == _kpiVisivel) setState(() { _kpiVisivel = !esconder; });
                return false;
              },
              child: _tab == 0 ? _tabUtilizadores() : _tab == 1 ? _tabConsultas() : _tabRelatorio(),
            )),

          ])),
          floatingActionButton: _tab == 0
              ? Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: MedShadow.button),
                  child: FloatingActionButton(onPressed: _abrirCriarMedico, backgroundColor: MedColors.teal, foregroundColor: Colors.white,
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Icon(Icons.person_add_rounded, size: 24)))
              : _tab == 1
              ? Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: MedShadow.button),
                  child: FloatingActionButton(onPressed: abrirCriarConsulta, backgroundColor: MedColors.purple, foregroundColor: Colors.white,
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Icon(Icons.add_rounded, size: 26)))
              : null,
        ));
  }

  Widget _tabUtilizadores() {
    final prov = Provider.of<AuthProvider>(context, listen: false);
    final adminUid = prov.utilizador?.uid ?? '';
    final adminNome = prov.utilizador?.nome ?? '';
    return Column(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: MedField(hint: 'Pesquisar utilizador...', controller: _txtPesquisa,
          prefix: Icon(Icons.search_rounded, color: MedColors.textHint, size: 20), onChanged: (v) => setState(() { _pesquisa = v; }))),
      SizedBox(height: 10),
      Expanded(child: StreamBuilder<List<Utilizador>>(
          stream: _us.todosUtilizadores(),
          builder: (ctx, snap) {
            var lista = (snap.data ?? []).where((u) => _pesquisa.isEmpty || u.nome.toLowerCase().contains(_pesquisa.toLowerCase()) || u.email.toLowerCase().contains(_pesquisa.toLowerCase())).toList();
            if (lista.isEmpty) return Center(child: Text('Nenhum utilizador', style: TextStyle(color: MedColors.textSub)));
            return ListView.builder(padding: EdgeInsets.symmetric(horizontal: 20), itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  var u = lista[i];
                  var info = _tipoInfo(u.tipo);
                  return MedCard(
                    onTap: () => _verDetalheUtilizador(u, adminUid, adminNome),
                    child: Row(children: [
                      Container(width: 46, height: 46, decoration: BoxDecoration(color: info['bg'], borderRadius: BorderRadius.circular(12)),
                          child: Icon(info['icon'] as IconData, color: info['cor'] as Color, size: 20)),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u.nome, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: MedColors.text)),
                        Text(u.email, style: TextStyle(fontSize: 11, color: MedColors.textSub)),
                        if (u.especializacao != null) Text(u.especializacao!, style: TextStyle(fontSize: 11, color: MedColors.teal, fontWeight: FontWeight.w600)),
                        if (u.idade != null) Text('${u.idade} anos', style: TextStyle(fontSize: 11, color: MedColors.textSub)),
                      ])),
                      MedBadge(texto: u.tipo, cor: info['bg'], corTexto: info['cor']),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: MedColors.textHint, size: 20),
                    ]));
                });
          })),
    ]);
  }

  Widget _tabConsultas() {
    return Column(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
        MedField(hint: 'Pesquisar paciente ou médico...', controller: _txtPesquisa,
            prefix: Icon(Icons.search_rounded, color: MedColors.textHint, size: 20), onChanged: (v) => setState(() { _pesquisa = v; })),
        SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['todos','pendente','confirmada','cancelada','realizada'].map((e) {
          bool sel = _filtroEstado == e;
          return GestureDetector(onTap: () => setState(() { _filtroEstado = e; }),
              child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: sel ? MedColors.purple : MedColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? MedColors.purple : MedColors.border)),
                  child: Text(e == 'todos' ? 'Todos' : labelEstado(e), style: TextStyle(fontSize: 12, color: sel ? Colors.white : MedColors.textSub, fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
        }).toList())),
        SizedBox(height: 10),
        _filtroData(),
      ])),
      SizedBox(height: 10),
      Expanded(child: StreamBuilder<List<Consulta>>(
          stream: _cs.todasConsultas(),
          builder: (ctx, snap) {
            var lista = _filtrarConsultas(snap.data ?? []);
            if (lista.isEmpty) return Center(child: Text('Nenhuma consulta', style: TextStyle(color: MedColors.textSub)));
            return ListView.builder(padding: EdgeInsets.symmetric(horizontal: 20), itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  var c = lista[i];
                  return MedCard(child: Row(children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(color: corEstadoBg(c.estado), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.calendar_today_rounded, color: corEstado(c.estado), size: 18)),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.pacienteNome, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: MedColors.text)),
                      Text('Dr. ${c.medicoNome}', style: TextStyle(fontSize: 12, color: MedColors.teal, fontWeight: FontWeight.w600)),
                      Text('${c.data}  ·  ${c.hora}', style: TextStyle(fontSize: 11, color: MedColors.textSub)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      MedBadge(texto: labelEstado(c.estado), cor: corEstadoBg(c.estado), corTexto: corEstado(c.estado)),
                      SizedBox(height: 4),
                      MedBadge(
                        texto: c.pagamentoEstado == 'pago' ? 'Pago' : 'Pendente',
                        cor: c.pagamentoEstado == 'pago' ? MedColors.successLight : MedColors.warningLight,
                        corTexto: c.pagamentoEstado == 'pago' ? MedColors.success : MedColors.warning,
                      ),
                      SizedBox(height: 4),
                      Row(children: [
                        GestureDetector(onTap: () => abrirEditarConsulta(c),
                            child: Container(width: 28, height: 28, decoration: BoxDecoration(color: MedColors.purpleLight, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit_rounded, color: MedColors.purple, size: 13))),
                        SizedBox(width: 4),
                        GestureDetector(onTap: () => confirmarEliminar(c),
                            child: Container(width: 28, height: 28, decoration: BoxDecoration(color: MedColors.dangerLight, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_rounded, color: MedColors.danger, size: 13))),
                      ]),
                    ]),
                  ]));
                });
          })),
    ]);
  }

  Widget _tabRelatorio() {
    return Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, 0), child: _filtroData()),
      Expanded(child: StreamBuilder<List<Consulta>>(
      stream: _cs.todasConsultas(),
      builder: (ctx, snap) {
        var lista = _filtrarPorData(snap.data ?? []);
        var pagas = lista.where((c) => c.pagamentoEstado == 'pago').toList();
        var porPagar = lista.where((c) => c.pagamentoEstado != 'pago' && c.estado != 'cancelada').toList();
        double totalReceita = pagas.fold(0.0, (sum, c) => sum + c.pagamentoValor);

        Map<String, double> porMetodo = {};
        List<Consulta> pSeguradora = [];
        for (var c in pagas) {
          if (c.pagamentoMetodo.isNotEmpty) {
            porMetodo[c.pagamentoMetodo] = (porMetodo[c.pagamentoMetodo] ?? 0) + c.pagamentoValor;
          }
          if (c.pagamentoMetodo == 'seguradora') pSeguradora.add(c);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              MedKpiCard(label: 'Receita total', valor: '${totalReceita.toStringAsFixed(0)} MZN', cor: MedColors.success, bgCor: MedColors.successLight, icon: Icons.payments_rounded),
              SizedBox(width: 10),
              MedKpiCard(label: 'Por pagar', valor: '${porPagar.length}', cor: MedColors.warning, bgCor: MedColors.warningLight, icon: Icons.pending_outlined),
            ]),
            SizedBox(height: 20),
            Text('Por método de pagamento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MedColors.text)),
            SizedBox(height: 10),
            if (porMetodo.isEmpty)
              Text('Sem pagamentos registados', style: TextStyle(fontSize: 13, color: MedColors.textSub))
            else
              ...porMetodo.entries.map((e) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border)),
                child: Row(children: [
                  Icon(_iconMetodo(e.key), color: MedColors.purple, size: 20),
                  SizedBox(width: 12),
                  Text(e.key[0].toUpperCase() + e.key.substring(1), style: TextStyle(fontWeight: FontWeight.w600, color: MedColors.text)),
                  Spacer(),
                  Text('${e.value.toStringAsFixed(0)} MZN', style: TextStyle(fontWeight: FontWeight.w700, color: MedColors.success)),
                ]),
              )),
            if (pSeguradora.isNotEmpty) ...[
              SizedBox(height: 20),
              Text('Detalhe — Seguradoras', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MedColors.text)),
              SizedBox(height: 10),
              ...pSeguradora.map((c) => Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: MedColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: MedColors.border)),
                child: Row(children: [
                  Icon(Icons.health_and_safety_rounded, color: MedColors.teal, size: 16),
                  SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.pacienteNome, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MedColors.text)),
                    if (c.seguradoraCodigo.isNotEmpty)
                      Text(c.seguradoraCodigo, style: TextStyle(fontSize: 11, color: MedColors.textSub)),
                  ])),
                  Text('${c.data}  ·  ${c.hora}', style: TextStyle(fontSize: 11, color: MedColors.textSub)),
                ]),
              )),
            ],
          ]),
        );
      },
    )),
    ]);
  }

  IconData _iconMetodo(String m) {
    if (m == 'mpesa' || m == 'emola') return Icons.phone_android_rounded;
    if (m == 'seguradora') return Icons.health_and_safety_rounded;
    if (m == 'Cartão') return Icons.credit_card_rounded;
    return Icons.payments_rounded;
  }
}