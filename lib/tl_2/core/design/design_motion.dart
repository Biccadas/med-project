import 'package:flutter/material.dart';

/// Movimento padronizado do MedLink.
///
/// Restrições de produto (não-negociáveis): animações curtas (≤300ms) e
/// subtis; NADA de animação contínua, pesada ou parallax — Android de gama
/// baixa e rede fraca são a norma, não a exceção. Sempre respeitar
/// `MediaQuery.of(context).disableAnimations` ("reduzir movimento" do sistema).
///
/// Curvas de ease-out (começa rápido, acaba devagar) por defeito — é o que o
/// apple-design chama de "critically damped": assentamento suave, sem
/// oscilação/bounce. Overshoot/elastic fica reservado para gestos com
/// momentum reais (arrastar/largar), que esta app não usa — por isso não
/// existe uma curva "bounce" nestes tokens.
class MedMotion {
  MedMotion._();

  /// Feedback de toque instantâneo (ex. escala ao pressionar um botão).
  static const fast = Duration(milliseconds: 120);

  /// Transições e entradas por defeito (cartões, pills, campos).
  static const base = Duration(milliseconds: 200);

  /// Teto do produto — nunca ultrapassar (ex. abrir uma folha/sheet).
  static const slow = Duration(milliseconds: 300);

  static const curve = Curves.easeOutCubic;

  /// Devolve [base] respeitando "reduzir movimento": Duration.zero quando
  /// o utilizador pediu menos animação ao sistema operativo.
  static Duration duration(BuildContext context, [Duration base = MedMotion.base]) {
    if (MediaQuery.of(context).disableAnimations) return Duration.zero;
    return base;
  }
}
