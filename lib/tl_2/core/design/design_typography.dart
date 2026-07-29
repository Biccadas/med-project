import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// Escala tipográfica do MedLink — Plus Jakarta Sans (geométrica, humanista,
/// muito legível; escolhida para um público que pode ter baixa literacia
/// digital — nada de fontes decorativas/condensadas).
///
/// Tracking negativo em texto grande, perto de zero em texto de leitura
/// (regra do apple-design: "large text wants negative tracking; small text
/// wants slightly positive/near-zero for legibility").
class MedType {
  MedType._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required double height,
    required double tracking,
    Color color = MedColors.textPrimary,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: tracking,
        color: color,
      );

  /// Título de ecrã grande (ex. cabeçalho "Administração").
  static TextStyle display({Color color = MedColors.textPrimary}) =>
      _base(size: 28, weight: FontWeight.w800, height: 34 / 28, tracking: -0.5, color: color);

  /// Título de secção.
  static TextStyle title({Color color = MedColors.textPrimary}) =>
      _base(size: 22, weight: FontWeight.w800, height: 28 / 22, tracking: -0.3, color: color);

  /// Subtítulo / cabeçalho de cartão.
  static TextStyle subtitle({Color color = MedColors.textPrimary}) =>
      _base(size: 17, weight: FontWeight.w700, height: 24 / 17, tracking: -0.1, color: color);

  /// Corpo de texto principal.
  static TextStyle body({Color color = MedColors.textPrimary}) =>
      _base(size: 15, weight: FontWeight.w500, height: 22 / 15, tracking: 0, color: color);

  /// Corpo de texto em destaque (ex. valor importante, botão).
  static TextStyle bodyStrong({Color color = MedColors.textPrimary}) =>
      _base(size: 15, weight: FontWeight.w700, height: 22 / 15, tracking: 0, color: color);

  /// Texto de apoio / legendas.
  static TextStyle caption({Color color = MedColors.textSecondary}) =>
      _base(size: 13, weight: FontWeight.w500, height: 18 / 13, tracking: 0.1, color: color);

  /// Etiqueta pequena (pills, eyebrow) — maiúsculas, usar com moderação.
  static TextStyle label({Color color = MedColors.textSecondary}) =>
      _base(size: 11, weight: FontWeight.w700, height: 14 / 11, tracking: 0.6, color: color);
}
