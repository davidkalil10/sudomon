import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/logic_grid.dart';
import '../models/grid_cell.dart';
import '../models/enums.dart';
import '../models/map_theme.dart';

class LogicGridWidget extends StatelessWidget {
  final LogicGrid logicGrid;
  final String playerAsset;
  final MapTheme theme;
  final bool isReference;

  const LogicGridWidget({
    super.key,
    required this.logicGrid,
    required this.playerAsset,
    required this.theme,
    this.isReference = false,
  });

  @override
  Widget build(BuildContext context) {
    int rows = logicGrid.grid.length;
    int cols = logicGrid.grid[0].length;

    return AspectRatio(
      aspectRatio: cols / rows,
      child: Container(
        decoration: BoxDecoration(
          // Borda externa preta grossa para fechar o mapa
          border: Border.all(color: Colors.black, width: 3),
          color: theme.fallbackColor,
        ),
        child: Column(
          children: List.generate(rows, (r) {
            return Expanded(
              child: Row(
                children: List.generate(cols, (c) {
                  int myZone = logicGrid.grid[r][c].zoneId;

                  // Verifica vizinhos para saber onde desenhar a borda grossa
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
                      playerAsset: playerAsset,
                      theme: theme,
                      isReference: isReference,
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
  final String playerAsset;
  final MapTheme theme;
  final bool isReference;

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
    required this.playerAsset,
    required this.theme,
    required this.isReference,
  });

  // --- NOVA FUNÇÃO DE CORES INTENSAS ---
  Color _getZoneBorderColor(int zoneId) {
    // Lista de cores de alto contraste e vibrantes
    const List<Color> zoneColors = [
      Color(0xFFFF1744), // Vermelho Neon (Zona 0)
      Color(0xFF2979FF), // Azul Elétrico (Zona 1)
      Color(0xFF00E676), // Verde Brilhante (Zona 2)
      Color(0xFFFFC400), // Âmbar/Ouro (Zona 3)
      Color(0xFFD500F9), // Roxo Vibrante (Zona 4)
      Color(0xFF00E5FF), // Ciano (Zona 5)
      Color(0xFFFF9100), // Laranja (Zona 6)
      Color(0xFFE040FB), // Magenta (Zona 7)
    ];
    return zoneColors[zoneId % zoneColors.length];
  }

  BoxDecoration _getDecoration() {
    String assetPath = theme.getAssetForZone(cell.zoneId);

    // Pega a cor específica desta zona
    final Color myZoneColor = _getZoneBorderColor(cell.zoneId);

    // Borda grossa e colorida para as Zonas
    final zoneBorder = BorderSide(color: myZoneColor, width: 3.5); // Aumentei para 3.5

    // Borda fina e transparente para a grade interna (apenas para guiar o olho)
    const gridBorder = BorderSide(color: Colors.black12, width: 0.5);

    return BoxDecoration(
      color: theme.fallbackColor,
      image: DecorationImage(
        image: ResizeImage(
          AssetImage(assetPath),
          width: 64,
          height: 64,
        ),
        repeat: ImageRepeat.repeat,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
        isAntiAlias: false,
      ),
      border: Border(
        // Se for divisa de zona, usa a cor vibrante. Se não, usa a grade fina.
        top: borderTop ? zoneBorder : (row == 0 ? BorderSide.none : gridBorder),
        bottom: borderBottom ? zoneBorder : (row == totalRows - 1 ? BorderSide.none : gridBorder),
        left: borderLeft ? zoneBorder : (col == 0 ? BorderSide.none : gridBorder),
        right: borderRight ? zoneBorder : (col == totalCols - 1 ? BorderSide.none : gridBorder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _getDecoration(),
      child: Center(
        child: _buildCellContent(),
      ),
    );
  }

  Widget _buildCellContent() {
    // Lógica de "Reference Map" (Mapa Limpo)
    if (isReference) {
      if (cell.type == CellType.player || cell.type == CellType.character) {
        return const SizedBox.shrink();
      }
    }

    if (cell.type == CellType.empty) return const SizedBox.shrink();

    Widget content;

    if (cell.type == CellType.player) {
      content = Image(
        image: ResizeImage(AssetImage(playerAsset), width: 64, height: 64),
        filterQuality: FilterQuality.none,
        isAntiAlias: false,
        fit: BoxFit.contain,
      );
    }
    else if (cell.type == CellType.stone) {
      content = Image(
        image: ResizeImage(AssetImage(theme.obstacleAsset), width: 64, height: 64),
        filterQuality: FilterQuality.none,
        isAntiAlias: false,
        fit: BoxFit.contain,
      );
    }
    else if (cell.type == CellType.character && cell.value.startsWith('http')) {
      content = Transform.scale(
        scale: 1.5,
        child: CachedNetworkImage(
          imageUrl: cell.value,
          filterQuality: FilterQuality.none,
          placeholder: (context, url) => const SizedBox(
              width: 10, height: 10,
              child: CircularProgressIndicator(strokeWidth: 2)
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
          fit: BoxFit.contain,
        ),
      );
    } else {
      content = Text(cell.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
    }

    return content;
  }
}