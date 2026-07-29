import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import '../firebase_options.dart';
import 'providers/auth_provider.dart';
import 'repositories/utilizador_repository.dart';
import 'repositories/firebase/firebase_utilizador_repository.dart';
import 'repositories/disponibilidade_repository.dart';
import 'repositories/firebase/firebase_disponibilidade_repository.dart';
import 'views/auth/login_tela.dart';
import 'views/auth/registo_tela.dart';
import 'views/paciente/paciente_tela.dart';
import 'views/medico/medico_tela.dart';
import 'views/admin/admin_tela.dart';
import 'core/tema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => MinhaApp(),
  ));
}

class MinhaApp extends StatelessWidget {
  const MinhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..carregarUtilizador()),
        Provider<UtilizadorRepository>(create: (_) => FirebaseUtilizadorRepository()),
        Provider<DisponibilidadeRepository>(create: (_) => FirebaseDisponibilidadeRepository()),
      ],
      child: MaterialApp(
        title: 'MedLink',
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: ThemeData(
          scaffoldBackgroundColor: MedColors.bg,
          colorScheme: ColorScheme.light(primary: MedColors.accent, surface: MedColors.surface),
          useMaterial3: true,
        ),
        routes: {
          '/': (context) => TelaInicial(),
          '/registo': (context) => RegistoTela(),
        },
      ),
    );
  }
}

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    var prov = Provider.of<AuthProvider>(context);
    if (prov.carregando) return Scaffold(backgroundColor: MedColors.bg, body: Center(child: CircularProgressIndicator(color: MedColors.accent)));
    if (!prov.estaLogado) return LoginTela();
    if (prov.tipo == 'medico') return MedicoTela();
    if (prov.tipo == 'admin') return AdminTela();
    return PacienteTela();
  }
}