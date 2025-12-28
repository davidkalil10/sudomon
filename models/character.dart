import '../models/position.dart';
import '../models/monster.dart';

class Character {
  final String name; // Útil para lógica de dicas (A, B, C...)
  final Position position;
  final int zoneId;
  final Monster? monster; // <--- O Pokémon vinculado (pode ser null se for genérico)

  Character({
    required this.name,
    required this.position,
    required this.zoneId,
    this.monster,
  });
}