import 'package:flutter/material.dart';
import '../models/aviso.dart';
import '../repositories/consulta_repository.dart';

class MedColors {
  static const bg = Color(0xFFF8F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF0A1628);
  static const accent = Color(0xFF2563EB);
  static const accentLight = Color(0xFFEFF4FF);
  static const text = Color(0xFF0A1628);
  static const textSub = Color(0xFF6B7280);
  static const textHint = Color(0xFFB0B7C3);
  static const border = Color(0xFFE5E9F2);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEF2F2);
  static const teal = Color(0xFF0D9488);
  static const tealLight = Color(0xFFF0FDFA);
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFF5F3FF);
  static const realizada = Color(0xFF6366F1);
  static const realizadaLight = Color(0xFFEEF2FF);
  static const navBg = Color(0xFFFFFFFF);
}

class MedShadow {
  static List<BoxShadow> card = [
    BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 4)),
  ];
  static List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static List<BoxShadow> button = [
    BoxShadow(color: Color(0x402563EB), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static List<BoxShadow> nav = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -4)),
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, -1)),
  ];
}

Color corEstado(String e) {
  if (e == 'confirmada') return MedColors.success;
  if (e == 'cancelada') return MedColors.danger;
  if (e == 'realizada') return MedColors.realizada;
  return MedColors.warning;
}
Color corEstadoBg(String e) {
  if (e == 'confirmada') return MedColors.successLight;
  if (e == 'cancelada') return MedColors.dangerLight;
  if (e == 'realizada') return MedColors.realizadaLight;
  return MedColors.warningLight;
}
String labelEstado(String e) {
  if (e == 'confirmada') return 'Confirmada';
  if (e == 'cancelada') return 'Cancelada';
  if (e == 'realizada') return 'Realizada';
  return 'Pendente';
}

String formatarData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

DateTime? parsearData(String s) {
  try {
    final p = s.split('/');
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  } catch (_) { return null; }
}

class MedField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? prefix;
  final void Function(String)? onChanged;

  const MedField({super.key, required this.hint, required this.controller,
    this.obscure = false, this.keyboard, this.prefix, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MedColors.border, width: 1.5),
          boxShadow: [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))]),
      child: TextField(
          controller: controller, obscureText: obscure, keyboardType: keyboard, onChanged: onChanged,
          style: TextStyle(fontSize: 15, color: MedColors.text, fontWeight: FontWeight.w500),
          decoration: InputDecoration(hintText: hint,
              hintStyle: TextStyle(color: MedColors.textHint, fontWeight: FontWeight.w400),
              prefixIcon: prefix, border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16))),
    );
  }
}

class MedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final Color? cor;

  const MedButton({super.key, required this.label, required this.onPressed, this.loading = false, this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: MedShadow.button),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: cor ?? MedColors.accent, foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
        child: loading
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: .5)),
      ),
    );
  }
}

class MedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;

  const MedCard({super.key, required this.child, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(color: color ?? MedColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MedColors.border, width: 1), boxShadow: MedShadow.card),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(16),
          child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap,
              child: Padding(padding: padding ?? EdgeInsets.all(16), child: child))),
    );
  }
}

class MedBadge extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color corTexto;

  const MedBadge({super.key, required this.texto, required this.cor, required this.corTexto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(color: corTexto, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .3)),
    );
  }
}

class MedHeader extends StatelessWidget {
  final String titulo;
  final String? subtitulo;

  const MedHeader({super.key, required this.titulo, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: MedColors.text, letterSpacing: -.5)),
      if (subtitulo != null) ...[SizedBox(height: 4),
        Text(subtitulo!, style: TextStyle(fontSize: 14, color: MedColors.textSub, fontWeight: FontWeight.w400))],
    ]);
  }
}

class MedKpiCard extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  final Color bgCor;
  final IconData icon;

  const MedKpiCard({super.key, required this.label, required this.valor, required this.cor, required this.bgCor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgCor, borderRadius: BorderRadius.circular(14), border: Border.all(color: cor.withOpacity(.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: cor.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: cor, size: 16)),
        SizedBox(height: 10),
        Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cor)),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: cor.withOpacity(.7), fontWeight: FontWeight.w500)),
      ]),
    ));
  }
}

Widget sheetField(TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType? keyboard}) {
  return Container(
    decoration: BoxDecoration(color: MedColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border, width: 1.5)),
    child: TextField(controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
        style: TextStyle(fontSize: 14, color: MedColors.text),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: MedColors.textHint, fontSize: 13),
            border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
  );
}

Widget sheetDropdown<T>(String hint, T? val, List<DropdownMenuItem<T>> items, void Function(T?) onChange) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: MedColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border, width: 1.5)),
    child: DropdownButtonHideUnderline(child: DropdownButton<T>(isExpanded: true,
        hint: Text(hint, style: TextStyle(color: MedColors.textHint)), value: val, items: items, onChanged: onChange)),
  );
}

Widget datePicker(BuildContext context, DateTime? data, String hint, void Function(DateTime) onPick, {bool allowPast = false}) {
  return GestureDetector(
    onTap: () async {
      var d = await showDatePicker(
        context: context,
        initialDate: data ?? DateTime.now(),
        firstDate: allowPast ? DateTime(2020) : DateTime.now(),
        lastDate: DateTime(2030),
      );
      if (d != null) onPick(d);
    },
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: MedColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border, width: 1.5)),
      child: Row(children: [
        Icon(Icons.calendar_today_rounded, color: MedColors.textHint, size: 17),
        SizedBox(width: 10),
        Text(data != null ? formatarData(data) : hint,
            style: TextStyle(fontSize: 14, color: data != null ? MedColors.text : MedColors.textHint)),
      ]),
    ),
  );
}

Widget timePicker(BuildContext context, TimeOfDay? hora, String hint, void Function(TimeOfDay) onPick) {
  String label = hora != null
      ? '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'
      : hint;
  return GestureDetector(
    onTap: () async {
      var h = await showTimePicker(
        context: context,
        initialTime: hora ?? TimeOfDay(hour: 9, minute: 0),
        builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
      );
      if (h != null) onPick(h);
    },
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: MedColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border, width: 1.5)),
      child: Row(children: [
        Icon(Icons.access_time_rounded, color: MedColors.textHint, size: 17),
        SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: hora != null ? MedColors.text : MedColors.textHint)),
      ]),
    ),
  );
}

class AvisosBadge extends StatelessWidget {
  final Stream<List<Aviso>> stream;
  final VoidCallback onTap;

  const AvisosBadge({super.key, required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border), boxShadow: MedShadow.card),
        child: StreamBuilder<List<Aviso>>(
          stream: stream,
          builder: (ctx, snap) {
            int count = snap.data?.length ?? 0;
            return Stack(alignment: Alignment.center, children: [
              Icon(Icons.notifications_outlined, color: MedColors.textSub, size: 20),
              if (count > 0) Positioned(top: 6, right: 6, child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(color: MedColors.danger, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('$count', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
              )),
            ]);
          },
        ),
      ),
    );
  }
}

void mostrarAvisos(BuildContext context, Stream<List<Aviso>> stream, ConsultaRepository service, String uid, {Function(Aviso)? onTapAviso}) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, isDismissible: true, enableDrag: true, backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * .75,
      decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Padding(padding: EdgeInsets.fromLTRB(20, 14, 20, 0), child: Column(children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: MedColors.border, borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Avisos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MedColors.text)),
            TextButton(onPressed: () => service.marcarTodosLidos(uid), child: Text('Marcar todos como lidos', style: TextStyle(fontSize: 12, color: MedColors.accent))),
          ]),
        ])),
        Divider(height: 16, color: MedColors.border),
        Expanded(child: StreamBuilder<List<Aviso>>(
          stream: stream,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: MedColors.accent));
            }
            var lista = snap.data ?? [];
            if (lista.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_none_rounded, size: 48, color: MedColors.textHint),
              SizedBox(height: 12),
              Text('Sem avisos', style: TextStyle(color: MedColors.textSub)),
            ]));
            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: lista.length,
              itemBuilder: (ctx, i) {
                var a = lista[i];
                bool lido = a.lido;
                return GestureDetector(
                  onTap: onTapAviso != null ? () {
                    if (!lido) service.marcarAvisoLido(a.id);
                    Navigator.pop(ctx);
                    onTapAviso(a);
                  } : null,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: lido ? MedColors.bg : MedColors.accentLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: lido ? MedColors.border : MedColors.accent.withOpacity(.2))),
                    child: Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(
                          color: lido ? MedColors.border : MedColors.accent.withOpacity(.15), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_iconAviso(a.tipo), color: lido ? MedColors.textHint : MedColors.accent, size: 18)),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.titulo, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: MedColors.text)),
                        SizedBox(height: 2),
                        Text(a.corpo, style: TextStyle(fontSize: 12, color: MedColors.textSub)),
                      ])),
                      if (!lido) GestureDetector(
                        onTap: () => service.marcarAvisoLido(a.id),
                        child: Container(width: 8, height: 8, decoration: BoxDecoration(color: MedColors.accent, borderRadius: BorderRadius.circular(4))),
                      ),
                    ]),
                  ),
                );
              },
            );
          },
        )),
      ]),
    ),
  );
}

IconData _iconAviso(String tipo) {
  if (tipo == 'consulta_confirmada') return Icons.check_circle_outline_rounded;
  if (tipo == 'consulta_cancelada') return Icons.cancel_outlined;
  if (tipo == 'exame') return Icons.science_outlined;
  if (tipo == 'consulta_realizada') return Icons.task_alt_rounded;
  if (tipo == 'mensagem') return Icons.chat_bubble_outline_rounded;
  return Icons.notifications_outlined;
}
