import 'character.dart';
import 'position.dart';
import 'zone_structure.dart';

class GridSolution {
  final int size;
  final ZoneStructure zoneStructure;
  final Position playerPos;
  final int playerZoneId;
  final List<Character> characters;
  final int numStones;
  // Representação da matriz de IDs de zona
  final List<List<int>> zoneGrid;

  GridSolution({
    required this.size,
    required this.zoneStructure,
    required this.playerPos,
    required this.playerZoneId,
    required this.characters,
    required this.numStones,
    required this.zoneGrid,
  });

  // Retorna o personagem que está na mesma zona do jogador (objetivo do jogo)
  Character? getCharacterInPlayerZone() {
    try {
      return characters.firstWhere((char) => char.zoneId == playerZoneId);
    } catch (e) {
      return null;
    }
  }
}