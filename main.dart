import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Importa a tela que criamos

void main() {
  runApp(const SudomonApp());
}

class SudomonApp extends StatelessWidget {
  const SudomonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudomon Lógica',
      debugShowCheckedModeBanner: false, // Remove a faixa "Debug" do canto
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Usa o design system mais moderno do Google
      ),
      // Define a HomeScreen como a tela inicial do app
      home: const HomeScreen(),
    );
  }
}