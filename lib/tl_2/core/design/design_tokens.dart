import 'package:flutter/material.dart';

/// Sistema de design central do MedLink.
///
/// Uma só cor de marca (`brand`), usada com disciplina na ação principal.
/// Os papéis (paciente/médico/admin) NÃO repintam a app — diferenciam-se por
/// [MedRoleTag], uma etiqueta pequena com ícone + texto.
///
/// Contraste verificado (fórmula WCAG, luminância relativa sRGB):
/// - `brand` (branco por cima): 6.7:1
/// - `textPrimary` sobre `surface`: 17.9:1
/// - `textSecondary` sobre `surface`: 7.8:1
/// Todos acima do mínimo AA (4.5:1) para texto normal.
class MedColors {
  MedColors._();

  // Marca — única cor de ação principal.
  static const brand = Color(0xFF1D4ED8);
  static const brandPressed = Color(0xFF1640B0);
  static const brandSoft = Color(0xFFE9EFFD);

  // Superfícies e fundo.
  static const bg = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E5EA);

  // Texto — contraste real, não decorativo.
  static const textPrimary = Color(0xFF12181F);
  static const textSecondary = Color(0xFF495364);
  static const textHint = Color(0xFF6B7686);
  static const onBrand = Color(0xFFFFFFFF);

  // Estados semânticos (texto escuro sobre fundo muito claro = contraste alto por construção).
  static const success = Color(0xFF0F7A56);
  static const successSoft = Color(0xFFE7F9F1);
  static const warning = Color(0xFF92600A);
  static const warningSoft = Color(0xFFFFF6E5);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFEECEC);

  // Estado de consulta "realizada" — indicador, não cor de marca/ação.
  static const info = Color(0xFF3730A3);
  static const infoSoft = Color(0xFFEEF0FD);

  // Desativado — neutro, sem convite à ação. Controlos desativados estão
  // isentos do mínimo de contraste AA (não são texto nem ação disponível),
  // mas mantemos legibilidade razoável em vez de apagar por completo.
  static const disabled = Color(0xFFC7CBD1);
  static const onDisabled = Color(0xFF8A93A1);
}

enum EstadoConsulta { pendente, confirmada, realizada, cancelada }

class MedEstadoStyle {
  final String label;
  final Color cor;
  final Color corSuave;
  const MedEstadoStyle(this.label, this.cor, this.corSuave);
}

const _estadoStyles = {
  EstadoConsulta.pendente: MedEstadoStyle('Pendente', MedColors.warning, MedColors.warningSoft),
  EstadoConsulta.confirmada: MedEstadoStyle('Confirmada', MedColors.success, MedColors.successSoft),
  EstadoConsulta.realizada: MedEstadoStyle('Realizada', MedColors.info, MedColors.infoSoft),
  EstadoConsulta.cancelada: MedEstadoStyle('Cancelada', MedColors.danger, MedColors.dangerSoft),
};

MedEstadoStyle estadoStyle(EstadoConsulta e) => _estadoStyles[e]!;

/// Espaçamento em escala de 4dp — mantém ritmo consistente em toda a app.
class MedSpace {
  MedSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Alvo de toque mínimo recomendado (WCAG / Material) — nunca usar menos.
  static const minTouchTarget = 48.0;
}

class MedRadius {
  MedRadius._();
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

class MedShadow {
  MedShadow._();
  static const card = [
    BoxShadow(color: Color(0x0A0F1A2E), blurRadius: 10, offset: Offset(0, 4)),
  ];
  static const elevated = [
    BoxShadow(color: Color(0x140F1A2E), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

enum MedPapel { paciente, medico, admin }

class _PapelInfo {
  final String label;
  final Color dot;
  final IconData icon;
  const _PapelInfo(this.label, this.dot, this.icon);
}

const _papelInfo = {
  MedPapel.paciente: _PapelInfo('Paciente', MedColors.brand, Icons.person_rounded),
  MedPapel.medico: _PapelInfo('Médico', MedColors.success, Icons.medical_services_rounded),
  MedPapel.admin: _PapelInfo('Administrador', MedColors.textSecondary, Icons.admin_panel_settings_rounded),
};

/// Etiqueta pequena que diferencia o papel do utilizador — NÃO repinta a app.
/// Ícone SEMPRE acompanhado de texto (nunca só o ícone).
class MedRoleTag extends StatelessWidget {
  final MedPapel papel;
  const MedRoleTag({super.key, required this.papel});

  @override
  Widget build(BuildContext context) {
    final info = _papelInfo[papel]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MedSpace.md, vertical: MedSpace.xs),
      decoration: BoxDecoration(
        color: MedColors.surface,
        borderRadius: BorderRadius.circular(MedRadius.pill),
        border: Border.all(color: MedColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: info.dot, shape: BoxShape.circle)),
        const SizedBox(width: MedSpace.sm),
        Icon(info.icon, size: 14, color: MedColors.textSecondary),
        const SizedBox(width: MedSpace.xs),
        Text(info.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MedColors.textSecondary)),
      ]),
    );
  }
}
