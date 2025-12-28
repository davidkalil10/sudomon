import 'dart:math';
import 'package:flutter/material.dart';
import '../generators/logic_grid_generator.dart';
import '../models/logic_grid.dart';
import '../widgets/game_board.dart';
import '../services/dex_service.dart';
import '../models/monster.dart';
import '../models/map_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LogicGrid? grid;

  // Configurações de Gameplay
  double rows = 6;
  double cols = 6;
  double numCharacters = 5;
  double numStones = 8;
  double numZones = 4;
  bool allowEmptyZones = true;

  // Configurações Visuais
  String playerAsset = 'assets/images/boy.png';
  MapTheme currentTheme = AppThemes.all[0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateGrid();
    });
  }

  void _generateGrid() {
    final random = Random();
    int themeIndex = random.nextInt(AppThemes.all.length);
    currentTheme = AppThemes.all[themeIndex];

    // Debug para verificar a troca de bioma no console
    debugPrint("Bioma sorteado: ${currentTheme.name}");

    int totalMonstersNeeded = numCharacters.toInt();
    List<Monster> roundMonsters = DexService().getMonstersForRound(totalMonstersNeeded);

    setState(() {
      grid = LogicGridGenerator.generate(
        rows: rows.toInt(),
        cols: cols.toInt(),
        numStones: numStones.toInt(),
        monsters: roundMonsters,
        numZones: numZones.toInt(),
        allowEmptyZones: allowEmptyZones,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cálculos de limites dinâmicos
    double maxNPCs = (min(rows, cols) - 1).toDouble();
    if (maxNPCs < 1) maxNPCs = 1;
    if (numCharacters > maxNPCs) numCharacters = maxNPCs;

    double totalCells = rows * cols;
    double maxStones = (totalCells - (numCharacters + 1)) * 0.6; // Máximo de 60% de pedras
    if (numStones > maxStones) numStones = maxStones;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Sudomon Lógica", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _generateGrid,
          )
        ],
      ),
      body: Column(
        children: [
          // ÁREA DOS TABULEIROS
          Expanded(
            child: grid == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text("MAPA DE JOGO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  // Tabuleiro 1: Jogo Real (isReference: false)
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: LogicGridWidget(
                        logicGrid: grid!,
                        playerAsset: playerAsset,
                        theme: currentTheme,
                        isReference: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text("MAPA DE REFERÊNCIA (LIMPO)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  // Tabuleiro 2: Apenas terreno e pedras (isReference: true)
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: LogicGridWidget(
                        logicGrid: grid!,
                        playerAsset: playerAsset,
                        theme: currentTheme,
                        isReference: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PAINEL DE CONTROLE (BOTTOOM)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Configurações do Mapa", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAvatarOption('assets/images/boy.png'),
                    const SizedBox(width: 20),
                    _buildAvatarOption('assets/images/girl.png'),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  children: [
                    Expanded(child: _buildSlider("Linhas", 6, 10, rows, (v) => rows = v)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSlider("Colunas", 6, 10, cols, (v) => cols = v)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildSlider("Cores", 4, 8, numZones, (v) => numZones = v)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSlider("Personagens", 1, maxNPCs, numCharacters, (v) => numCharacters = v)),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateGrid,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("GERAR NOVO DESAFIO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarOption(String assetPath) {
    bool isSelected = playerAsset == assetPath;
    return GestureDetector(
      onTap: () => setState(() => playerAsset = assetPath),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 3),
        ),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          child: ClipOval(
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none, // Pixel Art nítido
              errorBuilder: (ctx, _, __) => const Icon(Icons.person),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double min, double max, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toInt()}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: Colors.blue,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }
}