import 'dart:math';
import 'package:flutter/material.dart';
import '../generators/logic_grid_generator.dart';
import '../models/logic_grid.dart';
import '../widgets/game_board.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LogicGrid? grid;

  // Valores iniciais
  double rows = 6;
  double cols = 6;
  double numCharacters = 5; // NPCs (Excluindo jogador)
  double numStones = 10;

  @override
  void initState() {
    super.initState();
    // Gera o primeiro grid logo ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateGrid();
    });
  }

  void _generateGrid() {
    setState(() {
      grid = LogicGridGenerator.generate(
        rows: rows.toInt(),
        cols: cols.toInt(),
        numStones: numStones.toInt(),
        numCharacters: numCharacters.toInt(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. CALCULAR LIMITES DINÂMICOS

    // Máximo de NPCs possíveis (Sem contar o jogador)
    // Ex: Grid 6x8. O menor lado é 6. Cabem 6 entidades únicas nas linhas.
    // Tirando 1 linha para o jogador, sobram 5 para NPCs.
    double maxNPCs = (min(rows, cols) - 1).toDouble();

    // Garante que o valor selecionado não estoure o limite se reduzirmos o grid
    if (numCharacters > maxNPCs) numCharacters = maxNPCs;
    if (numCharacters < 1) numCharacters = 1; // Mínimo de 1 "Buddy"

    // Máximo de Pedras possíveis
    // Tudo que não é Jogador nem NPC pode virar pedra
    double totalCells = rows * cols;
    double usedCells = numCharacters + 1; // NPCs + Jogador
    double maxStones = totalCells - usedCells;

    // Garante que pedras não estoure o limite
    if (numStones > maxStones) numStones = maxStones;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Sudomon Lógica", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _generateGrid,
          )
        ],
      ),
      body: Column(
        children: [
          // ÁREA DO TABULEIRO
          Expanded(
            child: Center(
              child: grid == null
                  ? const CircularProgressIndicator()
                  : Padding(
                padding: const EdgeInsets.all(20.0),
                child: LogicGridWidget(logicGrid: grid!),
              ),
            ),
          ),

          // PAINEL DE CONTROLE
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30), // Mais padding embaixo
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Configurações",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                // Linha 1: Tamanho do Grid
                Row(
                  children: [
                    Expanded(child: _buildSlider("Linhas", 4, 10, rows, (v) => rows = v)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSlider("Colunas", 4, 10, cols, (v) => cols = v)),
                  ],
                ),

                const SizedBox(height: 5),

                // Linha 2: Elementos (Com limites dinâmicos)
                Row(
                  children: [
                    // Slider de NPCs (1 até Maximo Possível)
                    Expanded(child: _buildSlider("Inimigos", 1, maxNPCs, numCharacters, (v) => numCharacters = v)),
                    const SizedBox(width: 15),
                    // Slider de Pedras (0 até Ocupar Todo o Resto)
                    Expanded(child: _buildSlider("Pedras", 0, maxStones, numStones, (v) => numStones = v)),
                  ],
                ),

                const SizedBox(height: 15),

                // Botão Gerar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateGrid,
                    icon: const Icon(Icons.casino),
                    label: const Text("GERAR NOVO MAPA"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double min, double max, double value, Function(double) onChanged) {
    // Se por algum motivo min > max (ex: grid muito pequeno), trava no min
    if (max < min) max = min;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
            Text(
              "${value.toInt()} / ${max.toInt()}", // Mostra "Atual / Máximo"
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[700]),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.blue[400],
            inactiveTrackColor: Colors.grey[200],
            thumbColor: Colors.blue[600],
            overlayColor: Colors.blue.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            // Se o intervalo for muito grande, não usa divisions fixas para ficar fluido
            divisions: (max - min) > 0 ? (max - min).toInt() : 1,
            onChanged: (v) {
              setState(() {
                onChanged(v);
              });
            },
          ),
        ),
      ],
    );
  }
}