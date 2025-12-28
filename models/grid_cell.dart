import 'enums.dart';

class GridCell {
  final CellType type;
  final String value;
  final int zoneId;

  GridCell({
    required this.type,
    required this.value,
    required this.zoneId,
  });

  @override
  String toString() => 'GridCell(type=$type, value=$value, zone=$zoneId)';
}