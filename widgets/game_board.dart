import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/logic_grid.dart';
import '../models/grid_cell.dart';
import '../models/enums.dart';

class LogicGridWidget extends StatelessWidget {
  final LogicGrid logicGrid;
  final String playerAsset; // <--- 1. Novo parâmetro para receber a imagem

  const LogicGridWidget({
    super.key,
    required this.logicGrid,
    required this.playerAsset // <--- Adicionado ao construtor
  });

  @override
  Widget build(BuildContext context) {
    int rows = logicGrid.grid.length;
    int cols = logicGrid.grid[0].length;

    return AspectRatio(
      aspectRatio: cols / rows,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          color: Colors.white,
        ),
        child: Column(
          children: List.generate(rows, (r) {
            return Expanded(
              child: Row(
                children: List.generate(cols, (c) {
                  // Lógica de Borda Inteligente
                  int myZone = logicGrid.grid[r][c].zoneId;

                  bool borderTop = r > 0 && logicGrid.grid[r - 1][c].zoneId != myZone;
                  bool borderBottom = r < rows - 1 && logicGrid.grid[r + 1][c].zoneId != myZone;
                  bool borderLeft = c > 0 && logicGrid.grid[r][c - 1].zoneId != myZone;
                  bool borderRight = c < cols - 1 && logicGrid.grid[r][c + 1].zoneId != myZone;

                  return Expanded(
                    child: _GridCellWidget(
                      cell: logicGrid.grid[r][c],
                      row: r,
                      col: c,
                      totalRows: rows,
                      totalCols: cols,
                      borderTop: borderTop,
                      borderBottom: borderBottom,
                      borderLeft: borderLeft,
                      borderRight: borderRight,
                      playerAsset: playerAsset, // <--- 2. Repassando para a célula
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _GridCellWidget extends StatelessWidget {
  final GridCell cell;
  final int row;
  final int col;
  final int totalRows;
  final int totalCols;
  final bool borderTop;
  final bool borderBottom;
  final bool borderLeft;
  final bool borderRight;
  final String playerAsset; // <--- Recebe aqui também

  const _GridCellWidget({
    required this.cell,
    required this.row,
    required this.col,
    required this.totalRows,
    required this.totalCols,
    required this.borderTop,
    required this.borderBottom,
    required this.borderLeft,
    required this.borderRight,
    required this.playerAsset, // <--- Obrigatório
  });

  Color _getZoneColor(int zoneId) {
    const colors = [
      Color(0xFFE3F2FD), // Azul Claro
      Color(0xFFFFEBEE), // Rosa Claro
      Color(0xFFE8F5E9), // Verde Claro
      Color(0xFFFFF3E0), // Laranja Claro
      Color(0xFFF3E5F5), // Roxo Claro
      Color(0xFFE0F7FA), // Ciano Claro
      Color(0xFFFFFDE7), // Amarelo Claro
      Color(0xFFECEFF1), // Cinza Claro
    ];
    return colors[zoneId % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    const zoneBorder = BorderSide(color: Colors.black54, width: 2.0);
    const gridBorder = BorderSide(color: Colors.black12, width: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: _getZoneColor(cell.zoneId),
        border: Border(
          top: borderTop ? zoneBorder : (row == 0 ? BorderSide.none : gridBorder),
          bottom: borderBottom ? zoneBorder : (row == totalRows - 1 ? BorderSide.none : gridBorder),
          left: borderLeft ? zoneBorder : (col == 0 ? BorderSide.none : gridBorder),
          right: borderRight ? zoneBorder : (col == totalCols - 1 ? BorderSide.none : gridBorder),
        ),
      ),
      child: Center(
        child: _buildCellContent(),
      ),
    );
  }

  Widget _buildCellContent() {
    if (cell.type == CellType.empty) return const SizedBox.shrink();

    if (cell.type == CellType.stone) {
      return const Text('🪨', style: TextStyle(fontSize: 24));
    }

    if (cell.type == CellType.player) {
      // --- 3. MUDANÇA DO BONECO ---
      // Removemos o Container azul e colocamos a imagem direto
      return Image.asset(
        playerAsset,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        // Caso a imagem não carregue, mostra um ícone de fallback simples
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, color: Colors.blue, size: 28);
        },
      );
    }

    if (cell.type == CellType.character) {
      if (cell.value.startsWith('http')) {
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: CachedNetworkImage(
            imageUrl: cell.value,
            placeholder: (context, url) => const Padding(
              padding: EdgeInsets.all(10.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
            fit: BoxFit.contain,
          ),
        );
      } else {
        return Text(
          cell.value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        );
      }
    }

    return Text(
      cell.value,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}