import 'package:flutter/material.dart';
import '../models/logic_grid.dart';
import '../models/grid_cell.dart';
import '../models/enums.dart';

// PARTE 1: O Desenho de uma única Célula
class GridCellWidget extends StatelessWidget {
  final GridCell cell;

  const GridCellWidget({super.key, required this.cell});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getZoneColor(cell.zoneId), // Pinta o fundo com a cor da zona
        border: Border.all(
          color: Colors.black.withOpacity(0.05), // Borda bem suave
          width: 0.5,
        ),
      ),
      child: Center(
        child: _buildContent(),
      ),
    );
  }

  // Define o que aparece dentro do quadrado
  Widget _buildContent() {
    switch (cell.type) {
      case CellType.player:
        return Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        );

      case CellType.character:
      // Personagem visível (A, B, C...)
        return Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8), // Fundo branco translúcido
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              cell.value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        );

      case CellType.safe:
      // O slot oculto (?)
        return Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26, width: 2), // Círculo vazio
          ),
          child: const Center(
            child: Text(
                "?",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)
            ),
          ),
        );

      case CellType.stone:
        return const Text('🪨', style: TextStyle(fontSize: 22));

      case CellType.empty:
      default:
        return const SizedBox(); // Não desenha nada, só mostra a cor do fundo
    }
  }

  // Paleta de Cores para as Zonas Orgânicas
  Color _getZoneColor(int zoneId) {
    // Lista de cores suaves (Pastel)
    final colors = [
      Color(0xFFE3F2FD), // Azul muito claro (Buddy/Player geralmente cai aqui se for 0)
      Color(0xFFFFEBEE), // Rosa claro
      Color(0xFFE8F5E9), // Verde claro
      Color(0xFFFFF3E0), // Laranja claro
      Color(0xFFF3E5F5), // Roxo claro
      Color(0xFFE0F7FA), // Ciano claro
      Color(0xFFFFFDE7), // Amarelo claro
      Color(0xFFECEFF1), // Cinza azulado
    ];
    // Usa o operador % para garantir que nunca estoure a lista
    return colors[zoneId % colors.length];
  }
}

// PARTE 2: O Grid que segura as células
class LogicGridWidget extends StatelessWidget {
  final LogicGrid logicGrid;

  const LogicGridWidget({super.key, required this.logicGrid});

  @override
  Widget build(BuildContext context) {
    // Recuperamos as dimensões do grid gerado
    final rows = logicGrid.solution.zoneStructure.rows;
    final cols = logicGrid.solution.zoneStructure.cols;

    return Center(
      child: AspectRatio(
        // Se temos 8 colunas e 4 linhas, a proporção é 2/1 (o dobro de largura)
        aspectRatio: cols / rows,
        child: Container(
          // Uma borda grossa ao redor do tabuleiro inteiro
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 2),
            color: Colors.grey[200], // Fundo de segurança
          ),
          child: GridView.builder(
            // Importante: Desativar scroll para o grid ficar fixo
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows * cols,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, // Define quantas colunas tem
              childAspectRatio: 1.0, // Força cada célula a ser quadrada perfeita
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemBuilder: (context, index) {
              // Matemática para converter índice linear (0..47) em (linha, coluna)
              final r = index ~/ cols;
              final c = index % cols;

              final cell = logicGrid.getCell(r, c);

              // Chama o widget da Célula que criamos acima
              return GridCellWidget(cell: cell);
            },
          ),
        ),
      ),
    );
  }
}