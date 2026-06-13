import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/tema.dart';

class LoginTela extends StatefulWidget {
  const LoginTela({super.key});
  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  var txtEmail = TextEditingController();
  var txtSenha = TextEditingController();
  String erro = '';

  void entrar() async {
    setState(() { erro = ''; });
    if (txtEmail.text.trim().isEmpty || txtSenha.text.trim().isEmpty) {
      setState(() { erro = 'Preencha o email e a senha.'; }); return;
    }
    var prov = Provider.of<AuthProvider>(context, listen: false);
    String? e = await prov.login(txtEmail.text.trim(), txtSenha.text.trim());
    if (e != null) setState(() { erro = 'Email ou senha incorrectos.'; });
  }

  void recuperarSenha() async {
    if (txtEmail.text.trim().isEmpty) {
      setState(() { erro = 'Insira o email para recuperar a senha.'; }); return;
    }
    var prov = Provider.of<AuthProvider>(context, listen: false);
    await prov.recuperarSenha(txtEmail.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email de recuperação enviado.'), backgroundColor: MedColors.success));
  }

  @override
  Widget build(BuildContext context) {
    var prov = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: MedColors.bg,
      body: SafeArea(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: EdgeInsets.symmetric(vertical: 52),
            decoration: BoxDecoration(color: MedColors.surface, border: Border(bottom: BorderSide(color: MedColors.border, width: 1))),
            child: Column(children: [
              Container(width: 72, height: 72,
                  decoration: BoxDecoration(color: MedColors.accent, borderRadius: BorderRadius.circular(22), boxShadow: MedShadow.button),
                  child: Icon(Icons.favorite_rounded, color: Colors.white, size: 34)),
              SizedBox(height: 18),
              Text('MedLink', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: MedColors.text, letterSpacing: -.5)),
              SizedBox(height: 6),
              Text('Sistema de Gestão de Saúde', style: TextStyle(fontSize: 13, color: MedColors.textSub)),
            ])),
        Padding(padding: EdgeInsets.fromLTRB(28, 36, 28, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Bem Vindo ao MedLink', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MedColors.text, letterSpacing: -.3)),
          SizedBox(height: 6),
          Text('Aceda à sua conta para continuar', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: MedColors.textSub)),
          SizedBox(height: 32),
          MedField(hint: 'Email', controller: txtEmail, keyboard: TextInputType.emailAddress,
              prefix: Icon(Icons.mail_outline_rounded, color: MedColors.textHint, size: 20)),
          SizedBox(height: 14),
          MedField(hint: 'Senha', controller: txtSenha, obscure: true,
              prefix: Icon(Icons.lock_outline_rounded, color: MedColors.textHint, size: 20)),
          SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: GestureDetector(
              onTap: recuperarSenha,
              child: Text('Esqueci a senha', style: TextStyle(fontSize: 13, color: MedColors.accent, fontWeight: FontWeight.w600)))),
          SizedBox(height: 10),
          if (erro.isNotEmpty) Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: MedColors.dangerLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: MedColors.danger.withOpacity(.2))),
              child: Row(children: [Icon(Icons.error_outline_rounded, color: MedColors.danger, size: 16), SizedBox(width: 8),
                Text(erro, style: TextStyle(color: MedColors.danger, fontSize: 13, fontWeight: FontWeight.w500))])),
          SizedBox(height: 20),
          MedButton(label: 'Entrar', onPressed: entrar, loading: prov.carregando),
          SizedBox(height: 20),
          Center(child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/registo'),
              child: RichText(text: TextSpan(
                  text: 'Não tem conta?  ',
                  style: TextStyle(color: MedColors.textSub, fontSize: 14),
                  children: [TextSpan(text: 'Criar conta', style: TextStyle(color: MedColors.accent, fontWeight: FontWeight.w700))])))),
        ])),
      ]))),
    );
  }
}