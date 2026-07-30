import 'package:flutter/material.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/design_typography.dart';
import '../../core/design/design_motion.dart';

/// Ecrã isolado de pré-visualização do sistema de design do MedLink.
///
/// Não faz parte de nenhum fluxo real da app — serve só para rever tokens
/// de cor, tipografia, componentes base e microinteração antes de aplicar a
/// direção estética aos ecrãs existentes (fora do âmbito desta tarefa).
class DesignPreviewTela extends StatefulWidget {
  const DesignPreviewTela({super.key});

  @override
  State<DesignPreviewTela> createState() => _DesignPreviewTelaState();
}

class _DesignPreviewTelaState extends State<DesignPreviewTela> with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;
  bool _reduzirMovimento = false;
  bool _entradaArrancada = false;

  @override
  void initState() {
    super.initState();
    // Nada aqui depende de context — só cria o controller, sem duração ainda
    // decidida (isso depende de MediaQuery, lido em didChangeDependencies).
    _entrada = AnimationController(vsync: this, duration: MedMotion.slow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // dependOnInheritedWidgetOfExactType (usado por MediaQuery.of) só pode
    // ser chamado depois de initState() ter terminado — aqui é o sítio certo.
    _reduzirMovimento = MediaQuery.of(context).disableAnimations;
    if (!_entradaArrancada) {
      _entradaArrancada = true;
      _entrada.duration = _reduzirMovimento ? Duration.zero : MedMotion.slow;
      _entrada.forward();
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  /// Cada secção entra com um pequeno desvanecer + deslize vertical,
  /// desfasado (stagger) por [ordem] — uma só vez, ao abrir o ecrã.
  /// Nunca contínua, nunca em loop. Sem "reduzir movimento", aparece direto.
  Widget _entradaAnimada(int ordem, Widget child) {
    if (_reduzirMovimento) return child;
    final inicio = (ordem * 0.08).clamp(0.0, 0.6);
    final fim = (inicio + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(parent: _entrada, curve: Interval(inicio, fim, curve: MedMotion.curve));
    return AnimatedBuilder(
      animation: anim,
      builder: (ctx, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: Offset(0, (1 - anim.value) * 12), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedColors.bg,
      appBar: AppBar(
        backgroundColor: MedColors.surface,
        foregroundColor: MedColors.textPrimary,
        elevation: 0,
        title: Text('Sistema de Design', style: MedType.subtitle()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(MedSpace.xl),
          children: [
            _entradaAnimada(0, _secao('Tipografia', const _SeccaoTipografia())),
            const SizedBox(height: MedSpace.xxl),
            _entradaAnimada(1, _secao('Cor', const _SeccaoCor())),
            const SizedBox(height: MedSpace.xxl),
            _entradaAnimada(2, _secao('Botões', const _SeccaoBotoes())),
            const SizedBox(height: MedSpace.xxl),
            _entradaAnimada(3, _secao('Cartões', const _SeccaoCartoes())),
            const SizedBox(height: MedSpace.xxl),
            _entradaAnimada(4, _secao('Pills de estado', const _SeccaoPills())),
            const SizedBox(height: MedSpace.xxl),
            _entradaAnimada(5, _secao('Campo de formulário', const _SeccaoCampo())),
            const SizedBox(height: MedSpace.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: MedType.title()),
      const SizedBox(height: MedSpace.lg),
      child,
    ]);
  }
}

class _SeccaoTipografia extends StatelessWidget {
  const _SeccaoTipografia();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Display 28/34', style: MedType.display()),
      const SizedBox(height: MedSpace.sm),
      Text('Título 22/28', style: MedType.title()),
      const SizedBox(height: MedSpace.sm),
      Text('Subtítulo 17/24', style: MedType.subtitle()),
      const SizedBox(height: MedSpace.sm),
      Text('Corpo de texto 15/22 — usado na maior parte da leitura da app.', style: MedType.body()),
      const SizedBox(height: MedSpace.sm),
      Text('Corpo em destaque 15/22', style: MedType.bodyStrong()),
      const SizedBox(height: MedSpace.sm),
      Text('Legenda / texto de apoio 13/18', style: MedType.caption()),
      const SizedBox(height: MedSpace.sm),
      Text('ETIQUETA 11/14', style: MedType.label()),
    ]);
  }
}

class _SeccaoCor extends StatelessWidget {
  const _SeccaoCor();

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: MedSpace.md, runSpacing: MedSpace.md, children: [
      _swatch('Marca', MedColors.brand, textoClaro: true),
      _swatch('Marca (pressionado)', MedColors.brandPressed, textoClaro: true),
      _swatch('Superfície', MedColors.surface),
      _swatch('Fundo', MedColors.bg),
      _swatch('Texto principal', MedColors.textPrimary, textoClaro: true),
      _swatch('Texto secundário', MedColors.textSecondary, textoClaro: true),
      _swatch('Sucesso', MedColors.success, textoClaro: true),
      _swatch('Aviso', MedColors.warning, textoClaro: true),
      _swatch('Perigo', MedColors.danger, textoClaro: true),
      _swatch('Info (realizada)', MedColors.info, textoClaro: true),
    ]);
  }

  Widget _swatch(String nome, Color cor, {bool textoClaro = false}) {
    return Container(
      width: 132,
      height: 84,
      padding: const EdgeInsets.all(MedSpace.md),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(MedRadius.md),
        border: Border.all(color: MedColors.border),
      ),
      alignment: Alignment.bottomLeft,
      child: Text(nome,
          style: MedType.caption(color: textoClaro ? Colors.white : MedColors.textPrimary)),
    );
  }
}

class _SeccaoBotoes extends StatelessWidget {
  const _SeccaoBotoes();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _BotaoPressionavel(label: 'Marcar consulta', icon: Icons.calendar_today_rounded),
      const SizedBox(height: MedSpace.sm),
      Text('Toque e segure para ver o estado pressionado (escala imediata, ${MedMotion.fast.inMilliseconds}ms).',
          style: MedType.caption()),
      const SizedBox(height: MedSpace.lg),
      Row(children: [
        Expanded(child: _estadoEstatico('Normal', pressionado: false)),
        const SizedBox(width: MedSpace.md),
        Expanded(child: _estadoEstatico('Pressionado', pressionado: true)),
      ]),
    ]);
  }

  Widget _estadoEstatico(String label, {required bool pressionado}) {
    return Transform.scale(
      scale: pressionado ? 0.97 : 1.0,
      child: Container(
        height: MedSpace.minTouchTarget + 6,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressionado ? MedColors.brandPressed : MedColors.brand,
          borderRadius: BorderRadius.circular(MedRadius.md),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
          const SizedBox(width: MedSpace.sm),
          Text(label, style: MedType.bodyStrong(color: Colors.white)),
        ]),
      ),
    );
  }
}

/// Botão real e interativo: escala para 0.97 no instante do toque
/// (`onTapDown`, não `onTap`) — feedback imediato, não à espera do largar.
class _BotaoPressionavel extends StatefulWidget {
  final String label;
  final IconData icon;
  const _BotaoPressionavel({required this.label, required this.icon});

  @override
  State<_BotaoPressionavel> createState() => _BotaoPressionavelState();
}

class _BotaoPressionavelState extends State<_BotaoPressionavel> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final reduzir = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressionado = true),
      onTapUp: (_) => setState(() => _pressionado = false),
      onTapCancel: () => setState(() => _pressionado = false),
      onTap: () {},
      child: AnimatedScale(
        scale: _pressionado ? 0.97 : 1.0,
        duration: reduzir ? Duration.zero : MedMotion.fast,
        curve: MedMotion.curve,
        child: Container(
          width: double.infinity,
          height: MedSpace.minTouchTarget + 6,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressionado ? MedColors.brandPressed : MedColors.brand,
            borderRadius: BorderRadius.circular(MedRadius.md),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: Colors.white, size: 18),
            const SizedBox(width: MedSpace.sm),
            Text(widget.label, style: MedType.bodyStrong(color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}

class _SeccaoCartoes extends StatelessWidget {
  const _SeccaoCartoes();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MedSpace.lg),
        decoration: BoxDecoration(
          color: MedColors.surface,
          borderRadius: BorderRadius.circular(MedRadius.lg),
          border: Border.all(color: MedColors.border),
          boxShadow: MedShadow.card,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Dra. Amélia Cossa', style: MedType.subtitle()),
            const MedRoleTag(papel: MedPapel.medico),
          ]),
          const SizedBox(height: MedSpace.xs),
          Text('Cardiologia · Consulta às 14:30', style: MedType.caption()),
        ]),
      ),
      const SizedBox(height: MedSpace.md),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MedSpace.lg),
        decoration: BoxDecoration(
          color: MedColors.surface,
          borderRadius: BorderRadius.circular(MedRadius.lg),
          border: Border.all(color: MedColors.border),
          boxShadow: MedShadow.card,
        ),
        child: Row(children: [
          const MedRoleTag(papel: MedPapel.paciente),
          const SizedBox(width: MedSpace.md),
          Expanded(child: Text('João Matsinhe · próxima consulta em 3 dias', style: MedType.body())),
        ]),
      ),
    ]);
  }
}

class _SeccaoPills extends StatelessWidget {
  const _SeccaoPills();

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: MedSpace.sm, runSpacing: MedSpace.sm, children: EstadoConsulta.values.map((e) {
      final s = estadoStyle(e);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: MedSpace.md, vertical: MedSpace.xs),
        decoration: BoxDecoration(color: s.corSuave, borderRadius: BorderRadius.circular(MedRadius.pill)),
        child: Text(s.label, style: MedType.caption(color: s.cor).copyWith(fontWeight: FontWeight.w700)),
      );
    }).toList());
  }
}

class _SeccaoCampo extends StatelessWidget {
  const _SeccaoCampo();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MedColors.surface,
        borderRadius: BorderRadius.circular(MedRadius.md),
        border: Border.all(color: MedColors.border, width: 1.5),
      ),
      child: TextField(
        style: MedType.body(),
        decoration: InputDecoration(
          hintText: 'Motivo da consulta',
          hintStyle: MedType.body(color: MedColors.textHint),
          prefixIcon: const Icon(Icons.edit_note_rounded, color: MedColors.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: MedSpace.lg, vertical: MedSpace.lg),
        ),
      ),
    );
  }
}
