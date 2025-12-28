import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/dex_service.dart'; // Importe o serviço

void main() async {
  // Garante que o binding do Flutter esteja pronto antes de chamar código async
  WidgetsFlutterBinding.ensureInitialized();

  // Inicia o carregamento da Pokedex em segundo plano
  // Não usamos 'await' aqui para não travar a abertura do app (Splash Screen branca).
  // O app vai abrir, e se a internet for rápida, carrega quase instantaneamente.
  // Uma abordagem mais robusta seria criar uma Tela de Splash, mas assim já funciona.
  await DexService().initialize();

  runApp(const SudomonApp());
}

class SudomonApp extends StatelessWidget {
  const SudomonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudomon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}