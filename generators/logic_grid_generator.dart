import 'dart:math';
import '../models/enums.dart';
import '../models/position.dart';
import '../models/zone_structure.dart';
import '../models/character.dart';
import '../models/grid_cell.dart';
import '../models/grid_solution.dart';
import '../models/logic_grid.dart';

class LogicGridGenerator {
  static const int maxAttempts = 200;

  static double _getDistance(int r1, int c1, int r2, int c2) {
    // Distância Euclidiana para zonas mais arredondadas
    return sqrt(pow(r1 - r2, 2) + pow(c1 - c2, 2));
  }

  static LogicGrid generate({
    int rows = 6,
    int cols = 6,
    int numStones = 4,
    int? numCharacters,
  }) {
    // Cálculo seguro de quantos chars cabem
    int maxPossibleChars = min(rows, cols);
    int actualNumCharacters = numCharacters ?? (maxPossibleChars - 1);
    if (actualNumCharacters >= maxPossibleChars) {
      actualNumCharacters = maxPossibleChars - 1;
    }

    final random = Random();
    int attempt = 0;

    while (attempt < maxAttempts) {
      attempt++;

      try {
        // 1. Grid e Listas
        List<List<GridCell>> grid = List.generate(
          rows,
              (r) => List.generate(
            cols,
                (c) => GridCell(type: CellType.empty, value: '.', zoneId: 0),
          ),
        );

        // 2. Posicionar Jogador
        final playerPos = Position(random.nextInt(rows), random.nextInt(cols));

        var availableRows = List.generate(rows, (i) => i)..remove(playerPos.row);
        var availableCols = List.generate(cols, (i) => i)..remove(playerPos.col);

        availableCols.shuffle(random);
        availableRows.shuffle(random);

        // 3. Posicionar Personagens (Sem definir Buddy ainda)
        List<Character> allPlacedCharacters = [];
        List<String> charNames = List.generate(26, (i) => String.fromCharCode(65 + i));

        // Quantos slots temos?
        int remainingSlots = min(availableRows.length, availableCols.length);

        // Vamos preencher a lista de personagens
        for (int i = 0; i < remainingSlots; i++) {
          int r = availableRows[i];
          int c = availableCols[i];

          // ID único temporário para cada char (começando de 0)
          int zoneId = i;

          // Cria o char (ainda sem saber se é visível ou oculto, decidimos depois)
          // Por enquanto, todos são placeholders
          allPlacedCharacters.add(
              Character(name: "TEMP", position: Position(r, c), zoneId: zoneId)
          );
        }

        // 4. GERAÇÃO DE ZONAS (Voronoi Puro)
        // Usamos TODOS os personagens como sementes. O Jogador NÃO é semente.
        // Assim, o Jogador vai "cair" naturalmente na zona de alguém.
        List<List<int>> finalZoneMap = List.generate(rows, (_) => List.filled(cols, 0));

        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            double minDistance = double.infinity;
            int chosenZoneId = 0;

            for (var seed in allPlacedCharacters) {
              double d = _getDistance(r, c, seed.position.row, seed.position.col);
              // Pequeno ruído para bordas orgânicas
              d += (random.nextDouble() * 0.2);

              if (d < minDistance) {
                minDistance = d;
                chosenZoneId = seed.zoneId;
              }
            }
            finalZoneMap[r][c] = chosenZoneId;
          }
        }

        // 5. IDENTIFICAR O BUDDY (Quem é dono da zona do jogador?)
        int playerZoneId = finalZoneMap[playerPos.row][playerPos.col];

        // Encontra o personagem que é dono dessa zona
        Character buddyChar = allPlacedCharacters.firstWhere((c) => c.zoneId == playerZoneId);

        // 6. DISTRIBUIR NOMES E VISIBILIDADE
        // Agora precisamos garantir que o Buddy seja Visível (Letra) e não Oculto (?)

        List<Character> finalCharacters = [];
        int nameIndex = 0;

        // Primeiro, configuramos o Buddy
        finalCharacters.add(Character(
            name: charNames[nameIndex++], // Recebe 'A' (ou a primeira letra)
            position: buddyChar.position,
            zoneId: buddyChar.zoneId
        ));

        // Quantos outros visíveis restam?
        int visibleOthersCount = actualNumCharacters - 1;

        for (var char in allPlacedCharacters) {
          if (char == buddyChar) continue; // Já processamos o buddy

          if (visibleOthersCount > 0) {
            // É um personagem visível
            finalCharacters.add(Character(
                name: charNames[nameIndex++],
                position: char.position,
                zoneId: char.zoneId
            ));
            visibleOthersCount--;
          } else {
            // É um personagem oculto (?)
            finalCharacters.add(Character(
                name: '?',
                position: char.position,
                zoneId: char.zoneId
            ));
          }
        }

        // 7. PREENCHER O GRID FINAL

        // 7.1 Jogador
        grid[playerPos.row][playerPos.col] = GridCell(
          type: CellType.player,
          value: '👤',
          zoneId: playerZoneId, // Agora é garantido ser natural
        );

        // 7.2 Personagens
        for (var char in finalCharacters) {
          CellType type = (char.name == '?') ? CellType.safe : CellType.character;

          grid[char.position.row][char.position.col] = GridCell(
            type: type,
            value: char.name,
            zoneId: finalZoneMap[char.position.row][char.position.col],
          );
        }

        // 7.3 Pedras e Vazios
        List<Position> emptyCells = [];
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            if (grid[r][c].type == CellType.empty) {
              int zId = finalZoneMap[r][c];
              grid[r][c] = GridCell(type: CellType.empty, value: '.', zoneId: zId);
              emptyCells.add(Position(r, c));
            }
          }
        }

        emptyCells.shuffle(random);
        int stonesToPlace = min(numStones, emptyCells.length);

        for (int i = 0; i < stonesToPlace; i++) {
          final pos = emptyCells[i];
          grid[pos.row][pos.col] = GridCell(
            type: CellType.stone,
            value: '🪨',
            zoneId: finalZoneMap[pos.row][pos.col],
          );
        }

        // 8. Retorno
        final validChars = finalCharacters
            .where((c) => c.name != '?')
            .toList();

        final solution = GridSolution(
          size: max(rows, cols),
          zoneStructure: ZoneStructure(rows, cols),
          playerPos: playerPos,
          playerZoneId: playerZoneId,
          characters: validChars,
          numStones: stonesToPlace,
          zoneGrid: finalZoneMap,
        );

        return LogicGrid(grid, solution);

      } catch (e) {
        continue;
      }
    }
    throw Exception("Falha ao gerar grid.");
  }
}