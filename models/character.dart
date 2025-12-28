import 'position.dart';

class Character {
  final String name;
  final Position position;
  final int zoneId;

  Character({
    required this.name,
    required this.position,
    required this.zoneId,
  });

  @override
  String toString() => 'Character(name=$name, pos=$position, zone=$zoneId)';
}