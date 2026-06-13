import 'package:flutter/material.dart';
import '../models/utilizador.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {

  final _service = AuthService();

  Utilizador? _utilizador;
  bool carregando = false;
  String erro = '';

  Utilizador? get utilizador => _utilizador;
  bool get estaLogado => _utilizador != null;
  String get tipo => _utilizador?.tipo ?? '';

  Future<void> carregarUtilizador() async {
    var atual = _service.utilizadorAtual;
    if (atual != null) {
      _utilizador = await _service.buscarUtilizador(atual.uid);
      notifyListeners();
    }
  }

  Future<String?> registar(String nome, String email, String senha, String tipo,
      {String telefone = '', int? idade, String? especializacao}) async {
    carregando = true; erro = ''; notifyListeners();
    String? erroRet = await _service.registar(nome, email, senha, tipo,
        telefone: telefone, idade: idade, especializacao: especializacao);
    if (erroRet == null) { await carregarUtilizador(); }
    else { erro = erroRet; }
    carregando = false; notifyListeners();
    return erroRet;
  }

  Future<String?> login(String email, String senha) async {
    carregando = true; erro = ''; notifyListeners();
    String? erroRet = await _service.login(email, senha);
    if (erroRet == null) { await carregarUtilizador(); }
    else { erro = erroRet; }
    carregando = false; notifyListeners();
    return erroRet;
  }

  Future<void> logout() async {
    await _service.logout();
    _utilizador = null;
    notifyListeners();
  }

  Future<void> recuperarSenha(String email) async {
    await _service.recuperarSenha(email);
  }

  Future<void> editarPerfil(String nome, String telefone, {String? especializacao}) async {
    if (_utilizador == null) return;
    await _service.editarPerfil(_utilizador!.uid, nome, telefone, especializacao: especializacao);
    _utilizador!.nome = nome;
    _utilizador!.telefone = telefone;
    if (especializacao != null) _utilizador!.especializacao = especializacao;
    notifyListeners();
  }
}