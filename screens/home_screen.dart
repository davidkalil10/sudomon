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

  // Configurações
  double rows = 6;
  double cols = 6;
  double numCharacters = 5;
  double numStones = 8;
  double numZones = 4;
  bool allowEmptyZones = true;

  @override
  void initState() {
    super.initState();
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
        numZones: numZones.toInt(),
        allowEmptyZones: allowEmptyZones,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO CRÍTICA: O limite matemático é o menor lado - 1 (para o jogador)
    // Ex: Grid 6x10 -> Min é 6 -> Max NPCs = 5.
    double maxNPCs = (min(rows, cols) - 1).toDouble();
    if (maxNPCs < 1) maxNPCs = 1;

    // Ajusta valor atual se estourar o novo limite
    if (numCharacters > maxNPCs) numCharacters = maxNPCs;
    if (numCharacters < 1) numCharacters = 1;

    // Limite de pedras
    double totalCells = rows * cols;
    double maxStones = totalCells - (numCharacters + 1);
    if (maxStones < 0) maxStones = 0;
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

          Container(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildSlider("Linhas", 6, 10, rows, (v) => rows = v)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSlider("Colunas", 6, 10, cols, (v) => cols = v)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(child: _buildSlider("Cores (Zonas)", 4, 10, numZones, (v) => numZones = v)),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        const Text("Zonas Livres", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                              value: allowEmptyZones,
                              activeColor: Colors.blue,
                              onChanged: (v) { setState(() => allowEmptyZones = v); }
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildSlider("Personagens", 1, maxNPCs, numCharacters, (v) => numCharacters = v)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSlider("Pedras", 0, maxStones, numStones, (v) => numStones = v)),
                  ],
                ),
                const SizedBox(height: 10),
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
    if (max < min) max = min;
    if (value < min) value = min;
    if (value > max) value = max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
            Text("${value.toInt()}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[700])),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.blue[400],
            inactiveTrackColor: Colors.grey[200],
            thumbColor: Colors.blue[600],
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min) > 0 ? (max - min).toInt() : 1,
            onChanged: (v) {
              setState(() => onChanged(v));
            },
          ),
        ),
      ],
    );
  }
}