import 'dart:math';
import '../models/enums.dart';
import '../models/position.dart';
import '../models/zone_structure.dart';
import '../models/character.dart';
import '../models/grid_cell.dart';
import '../models/grid_solution.dart';
import '../models/logic_grid.dart';
import '../models/monster.dart';

class LogicGridGenerator {
  static const int maxAttempts = 1000;

  static double _getDistance(int r1, int c1, int r2, int c2) {
    return sqrt(pow(r1 - r2, 2) + pow(c1 - c2, 2));
  }

  static LogicGrid generate({
    int rows = 6,
    int cols = 6,
    int numStones = 4,
    required List<Monster> monsters,
    int numZones = 4,
    bool allowEmptyZones = true,
  }) {
    if (rows < 6) rows = 6;
    if (cols < 6) cols = 6;
    if (numZones < 4) numZones = 4;

    int actualNumCharacters = monsters.length;
    int maxPossibleChars = min(rows, cols);
    if (actualNumCharacters >= maxPossibleChars) {
      actualNumCharacters = maxPossibleChars - 1;
    }
    if (actualNumCharacters < 1) actualNumCharacters = 1;

    final random = Random();
    int attempt = 0;

    while (attempt < maxAttempts) {
      attempt++;

      try {
        // --- PASSO 1: POSICIONAMENTO RÍGIDO (SUDOKU) ---
        List<Position> occupiedPositions = [];
        List<int> availRows = List.generate(rows, (i) => i);
        List<int> availCols = List.generate(cols, (i) => i);

        Position? pickSlot() {
          if (availRows.isEmpty || availCols.isEmpty) return null;
          int rIdx = random.nextInt(availRows.length);
          int cIdx = random.nextInt(availCols.length);
          int r = availRows[rIdx];
          int c = availCols[cIdx];
          availRows.removeAt(rIdx);
          availCols.removeAt(cIdx);
          return Position(r, c);
        }

        Position? playerPos = pickSlot();
        if (playerPos == null) continue;
        occupiedPositions.add(playerPos);

        Position? buddyPos = pickSlot();
        if (buddyPos == null) continue;
        occupiedPositions.add(buddyPos);

        List<Position> enemyPositions = [];
        int enemiesNeeded = actualNumCharacters - 1;

        for (int i = 0; i < enemiesNeeded; i++) {
          int subAttempt = 0;
          Position? candidate;
          bool valid = false;

          List<int> saveRows = List.from(availRows);
          List<int> saveCols = List.from(availCols);

          while (subAttempt < 20 && !valid) {
            availRows = List.from(saveRows);
            availCols = List.from(saveCols);
            candidate = pickSlot();
            if (candidate == null) break;

            int dRow = (candidate.row - playerPos.row).abs();
            int dCol = (candidate.col - playerPos.col).abs();

            if (dRow <= 1 && dCol <= 1) {
              subAttempt++;
            } else {
              valid = true;
            }
          }

          if (valid && candidate != null) {
            enemyPositions.add(candidate);
            occupiedPositions.add(candidate);
          } else {
            throw Exception("Falta de espaço seguro no grid");
          }
        }

        // --- PASSO 2: SEMENTES ---
        List<_ZoneSeed> seeds = [];

        // Player e Buddy recebem ID 0 LÓGICO
        seeds.add(_ZoneSeed(pos: playerPos, colorId: 0));
        seeds.add(_ZoneSeed(pos: buddyPos, colorId: 0));

        List<int> requiredColors = List.generate(numZones - 1, (i) => i + 1);
        List<Position> availableHolders = List.from(enemyPositions);

        while (availableHolders.length < requiredColors.length) {
          int r = random.nextInt(rows);
          int c = random.nextInt(cols);
          bool collision = occupiedPositions.any((p) => p.row == r && p.col == c) ||
              availableHolders.any((p) => p.row == r && p.col == c);
          if (!collision && ((r - playerPos.row).abs() > 1 || (c - playerPos.col).abs() > 1)) {
            availableHolders.add(Position(r, c));
          }
        }

        if (allowEmptyZones) {
          int extras = max(2, (rows * cols) ~/ 6);
          for(int i=0; i<extras; i++) {
            int r = random.nextInt(rows);
            int c = random.nextInt(cols);
            bool collision = occupiedPositions.any((p) => p.row == r && p.col == c) ||
                availableHolders.any((p) => p.row == r && p.col == c);
            if (!collision && ((r - playerPos.row).abs() > 1 || (c - playerPos.col).abs() > 1)) {
              availableHolders.add(Position(r, c));
            }
          }
        }

        // --- PASSO 3: CORES LÓGICAS ---
        availableHolders.shuffle(random);
        int holderIdx = 0;

        for (int color in requiredColors) {
          if (holderIdx < availableHolders.length) {
            seeds.add(_ZoneSeed(pos: availableHolders[holderIdx], colorId: color));
            holderIdx++;
          }
        }

        while (holderIdx < availableHolders.length) {
          int rndColor = 1 + random.nextInt(numZones - 1);
          seeds.add(_ZoneSeed(pos: availableHolders[holderIdx], colorId: rndColor));
          holderIdx++;
        }

        // --- PASSO 4: VORONOI ---
        List<List<int>> zoneMap = List.generate(rows, (_) => List.filled(cols, 0));
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            double minDist = double.infinity;
            int chosenColor = 0;
            for (var seed in seeds) {
              double d = _getDistance(r, c, seed.pos.row, seed.pos.col);
              if (d < minDist) {
                minDist = d;
                chosenColor = seed.colorId;
              } else if (d == minDist && seed.colorId == 0) {
                chosenColor = 0;
              }
            }
            zoneMap[r][c] = chosenColor;
          }
        }

        // --- PASSO 5: PÓS-PROCESSAMENTO ---
        _forceConnection(zoneMap, playerPos, buddyPos, rows, cols);
        _ensureMinZoneSize(zoneMap, rows, cols, seeds);

        // Validação de Cores
        Set<int> colorsFound = {};
        for(var row in zoneMap) {
          for(var val in row) colorsFound.add(val);
        }
        if (colorsFound.length < numZones) continue;

        // --- PASSO 6.5: O GRANDE TRUQUE (ALEATORIZAR AS CORES VIZUAIS) ---
        // Aqui desligamos o "Lógica 0" do "Visual Azul".
        // Criamos um mapa de tradução: {0: CorX, 1: CorY, 2: CorZ...}

        List<int> shuffledColors = List.generate(numZones, (i) => i);
        shuffledColors.shuffle(random); // Embaralha a paleta

        // Aplica a tradução no mapa inteiro
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            int logicId = zoneMap[r][c];
            // Se o ID lógico for maior que o número de cores (erro raro), usa módulo
            if (logicId >= numZones) logicId = logicId % numZones;

            zoneMap[r][c] = shuffledColors[logicId];
          }
        }

        // Descobre qual cor visual o Player ficou (pois precisamos saber disso para a lógica do jogo)
        // Antes era sempre 0. Agora é shuffledColors[0].
        int playerVisualZoneId = shuffledColors[0];

        // --- PASSO 7: POPULAR ---
        List<List<GridCell>> grid = List.generate(
          rows,
              (r) => List.generate(
            cols,
                (c) => GridCell(type: CellType.empty, value: '.', zoneId: zoneMap[r][c]),
          ),
        );

        List<Character> finalChars = [];
        List<String> logicNames = List.generate(26, (i) => String.fromCharCode(65 + i));
        int nameIdx = 0;

        // Buddy (Target)
        finalChars.add(Character(
          name: logicNames[nameIdx++],
          position: buddyPos,
          // A zona do buddy também mudou de cor visualmente, é a mesma do player
          zoneId: playerVisualZoneId,
          monster: monsters[0],
        ));

        // Inimigos
        for (int i = 0; i < enemyPositions.length; i++) {
          if (i + 1 >= monsters.length) break;
          Position pos = enemyPositions[i];
          int zId = zoneMap[pos.row][pos.col]; // Já está com a cor visual embaralhada
          Monster currentMonster = monsters[i + 1];

          finalChars.add(Character(
            name: logicNames[nameIdx++],
            position: pos,
            zoneId: zId,
            monster: currentMonster,
          ));
        }

        grid[playerPos.row][playerPos.col] = GridCell(
            type: CellType.player, value: '👤', zoneId: playerVisualZoneId
        );

        for (var c in finalChars) {
          CellType type = (c.name == '?') ? CellType.safe : CellType.character;
          String cellValue = c.monster != null ? c.monster!.imageUrl : c.name;
          grid[c.position.row][c.position.col] = GridCell(
              type: type, value: cellValue, zoneId: c.zoneId
          );
        }

        List<Position> stoneSlots = [];
        for(int r=0; r<rows; r++){
          for(int c=0; c<cols; c++){
            if(grid[r][c].type == CellType.empty) stoneSlots.add(Position(r, c));
          }
        }
        stoneSlots.shuffle(random);
        int finalStones = min(numStones, stoneSlots.length);
        for(int i=0; i<finalStones; i++){
          Position p = stoneSlots[i];
          grid[p.row][p.col] = GridCell(
              type: CellType.stone, value: '🪨', zoneId: zoneMap[p.row][p.col]
          );
        }

        final validChars = finalChars.where((c) => c.name != '?').toList();
        final solution = GridSolution(
          size: max(rows, cols),
          zoneStructure: ZoneStructure(rows, cols),
          playerPos: playerPos,
          // Atualiza a solução com a nova cor visual do player
          playerZoneId: playerVisualZoneId,
          characters: validChars,
          numStones: finalStones,
          zoneGrid: zoneMap,
        );

        return LogicGrid(grid, solution);

      } catch (e) {
        continue;
      }
    }
    throw Exception("Erro na geração.");
  }

  // --- MÉTODOS AUXILIARES ---
  // (Mantidos IGUAIS ao anterior: _ensureMinZoneSize e _forceConnection)
  // Copie-os do código anterior ou mantenha se já estiverem lá.
  // Vou incluí-los aqui para garantir que você tenha o arquivo completo.

  static void _ensureMinZoneSize(List<List<int>> map, int rows, int cols, List<_ZoneSeed> seeds) {
    for (var seed in seeds) {
      int myColor = seed.colorId;
      int sameColorNeighbors = 0;
      for(int r = seed.pos.row - 1; r <= seed.pos.row + 1; r++) {
        for(int c = seed.pos.col - 1; c <= seed.pos.col + 1; c++) {
          if (r >= 0 && r < rows && c >= 0 && c < cols) {
            if (r == seed.pos.row && c == seed.pos.col) continue;
            if (map[r][c] == myColor) sameColorNeighbors++;
          }
        }
      }
      if (sameColorNeighbors < 2) {
        for(int r = seed.pos.row - 1; r <= seed.pos.row + 1; r++) {
          for(int c = seed.pos.col - 1; c <= seed.pos.col + 1; c++) {
            if (r >= 0 && r < rows && c >= 0 && c < cols) {
              if (map[r][c] != 0) {
                map[r][c] = myColor;
              }
            }
          }
        }
      }
    }
  }

  static void _forceConnection(List<List<int>> map, Position start, Position end, int rows, int cols) {
    List<List<int>> queue = [];
    queue.add([start.row, start.col]);
    Set<String> visited = {};
    Map<String, List<int>> parent = {};
    visited.add("${start.row},${start.col}");
    bool found = false;
    while(queue.isNotEmpty) {
      var curr = queue.removeAt(0);
      if (curr[0] == end.row && curr[1] == end.col) { found = true; break; }
      [[0,1],[0,-1],[1,0],[-1,0]].forEach((d) {
        int nr = curr[0]+d[0], nc = curr[1]+d[1];
        if (nr>=0 && nr<rows && nc>=0 && nc<cols) {
          String k = "$nr,$nc";
          if (!visited.contains(k)) {
            visited.add(k);
            parent[k] = curr;
            queue.add([nr,nc]);
          }
        }
      });
    }
    if (found) {
      int r = end.row, c = end.col;
      while(r!=start.row || c!=start.col) {
        map[r][c] = 0;
        var p = parent["$r,$c"];
        if(p==null) break;
        r=p[0]; c=p[1];
      }
      map[start.row][start.col] = 0;
    }
  }
}

class _ZoneSeed {
  final Position pos;
  final int colorId;
  _ZoneSeed({required this.pos, required this.colorId});
}