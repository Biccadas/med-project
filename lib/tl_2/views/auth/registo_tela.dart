import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/tema.dart';

class RegistoTela extends StatefulWidget {
  const RegistoTela({super.key});
  @override
  State<RegistoTela> createState() => _RegistoTelaState();
}

class _RegistoTelaState extends State<RegistoTela> {

  var txtNome = TextEditingController();
  var txtEmail = TextEditingController();
  var txtSenha = TextEditingController();
  var txtSenhaConfirm = TextEditingController();
  var txtTelefone = TextEditingController();
  var txtIdade = TextEditingController();
  String erro = '';

  void registar() async {
    setState(() { erro = ''; });
    if (txtNome.text.trim().isEmpty || txtEmail.text.trim().isEmpty ||
        txtSenha.text.trim().isEmpty || txtTelefone.text.trim().isEmpty) {
      setState(() { erro = 'Preencha todos os campos obrigatórios.'; });
      return;
    }
    if (txtIdade.text.trim().isEmpty) {
      setState(() { erro = 'Indique a sua idade.'; });
      return;
    }
    if (txtSenha.text.trim().length < 6) {
      setState(() { erro = 'A senha deve ter pelo menos 6 caracteres.'; });
      return;
    }
    if (txtSenha.text.trim() != txtSenhaConfirm.text.trim()) {
      setState(() { erro = 'As senhas não coincidem.'; });
      return;
    }

    var prov = Provider.of<AuthProvider>(context, listen: false);
    String? erroReg = await prov.registar(
      txtNome.text.trim(), txtEmail.text.trim(), txtSenha.text.trim(), 'paciente',
      telefone: txtTelefone.text.trim(),
      idade: int.tryParse(txtIdade.text.trim()),
    );
    if (erroReg != null) {
      setState(() { erro = 'Erro ao criar conta. Tente outro email.'; });
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var prov = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: MedColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: MedColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedColors.border), boxShadow: MedShadow.card),
                    child: Icon(Icons.arrow_back_rounded, color: MedColors.text, size: 20)),
              ),

              SizedBox(height: 28),
              MedHeader(titulo: 'Criar conta.', subtitulo: 'Junte-se ao MedLink hoje'),
              SizedBox(height: 28),

              MedField(hint: 'Nome completo', controller: txtNome,
                  prefix: Icon(Icons.person_outline_rounded, color: MedColors.textHint, size: 20)),
              SizedBox(height: 12),
              MedField(hint: 'Email', controller: txtEmail, keyboard: TextInputType.emailAddress,
                  prefix: Icon(Icons.mail_outline_rounded, color: MedColors.textHint, size: 20)),
              SizedBox(height: 12),
              MedField(hint: 'Senha (mín. 6 caracteres)', controller: txtSenha, obscure: true,
                  prefix: Icon(Icons.lock_outline_rounded, color: MedColors.textHint, size: 20)),
              SizedBox(height: 12),
              MedField(hint: 'Confirmar senha', controller: txtSenhaConfirm, obscure: true,
                  prefix: Icon(Icons.lock_outline_rounded, color: MedColors.textHint, size: 20)),
              SizedBox(height: 12),
              MedField(hint: 'Número de telemóvel', controller: txtTelefone, keyboard: TextInputType.phone,
                  prefix: Icon(Icons.phone_outlined, color: MedColors.textHint, size: 20)),
              SizedBox(height: 12),
              MedField(hint: 'Idade', controller: txtIdade, keyboard: TextInputType.number,
                  prefix: Icon(Icons.cake_outlined, color: MedColors.textHint, size: 20)),

              SizedBox(height: 10),

              if (erro.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: MedColors.dangerLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: MedColors.danger.withOpacity(0.2))),
                  child: Row(children: [
                    Icon(Icons.error_outline_rounded, color: MedColors.danger, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(erro, style: TextStyle(color: MedColors.danger, fontSize: 13, fontWeight: FontWeight.w500))),
                  ]),
                ),

              SizedBox(height: 24),
              MedButton(label: 'Criar Conta', onPressed: registar, loading: prov.carregando),
              SizedBox(height: 40),

            ],
          ),
        ),
      ),
    );
  }
}
