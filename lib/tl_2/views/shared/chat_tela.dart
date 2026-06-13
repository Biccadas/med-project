import 'package:flutter/material.dart';
import '../../models/mensagem.dart';
import '../../services/chat_service.dart';
import '../../core/tema.dart';

class ChatTela extends StatefulWidget {
  final String meuId;
  final String meuNome;
  final String outroId;
  final String outroNome;

  const ChatTela({super.key, required this.meuId, required this.meuNome, required this.outroId, required this.outroNome});

  @override
  State<ChatTela> createState() => _ChatTelaState();
}

class _ChatTelaState extends State<ChatTela> {
  final _service = ChatService();
  final _txtMsg = TextEditingController();
  final _scroll = ScrollController();
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = _service.chatId(widget.meuId, widget.outroId);
  }

  @override
  void dispose() {
    _txtMsg.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _enviar() async {
    final texto = _txtMsg.text.trim();
    if (texto.isEmpty) return;
    _txtMsg.clear();
    await _service.enviar(
      Mensagem(id: '', chatId: _chatId, remetenteId: widget.meuId, texto: texto, criadoEm: DateTime.now().toIso8601String()),
      destinatarioId: widget.outroId,
      remetenteNome: widget.meuNome,
    );
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedColors.bg,
      appBar: AppBar(
        backgroundColor: MedColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: MedColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.outroNome, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MedColors.text)),
          Text('Conversa', style: TextStyle(fontSize: 11, color: MedColors.textSub)),
        ]),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: MedColors.border),
        ),
      ),
      body: Column(children: [
        Expanded(child: StreamBuilder<List<Mensagem>>(
          stream: _service.mensagens(_chatId),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: MedColors.accent));
            }
            var lista = snap.data ?? [];
            if (lista.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 64, height: 64,
                    decoration: BoxDecoration(color: MedColors.accentLight, borderRadius: BorderRadius.circular(18)),
                    child: Icon(Icons.chat_bubble_outline_rounded, color: MedColors.accent, size: 28)),
                SizedBox(height: 16),
                Text('Sem mensagens ainda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MedColors.text)),
                SizedBox(height: 6),
                Text('Envie a primeira mensagem', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
              ]));
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) {
                _scroll.jumpTo(_scroll.position.maxScrollExtent);
              }
            });
            return ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: lista.length,
              itemBuilder: (ctx, i) {
                final m = lista[i];
                final minha = m.remetenteId == widget.meuId;
                return Align(
                  alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * .72),
                    margin: EdgeInsets.only(bottom: 6),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: minha ? MedColors.accent : MedColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16), topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(minha ? 16 : 4),
                        bottomRight: Radius.circular(minha ? 4 : 16),
                      ),
                      boxShadow: MedShadow.card,
                    ),
                    child: Text(m.texto,
                        style: TextStyle(fontSize: 14, color: minha ? Colors.white : MedColors.text)),
                  ),
                );
              },
            );
          },
        )),
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: MedColors.surface,
            border: Border(top: BorderSide(color: MedColors.border)),
          ),
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(
                color: MedColors.bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: MedColors.border, width: 1.5),
              ),
              child: TextField(
                controller: _txtMsg,
                style: TextStyle(fontSize: 14, color: MedColors.text),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
                decoration: InputDecoration(
                  hintText: 'Escrever mensagem...',
                  hintStyle: TextStyle(color: MedColors.textHint, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            )),
            SizedBox(width: 10),
            GestureDetector(
              onTap: _enviar,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: MedColors.accent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: MedShadow.button,
                ),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
