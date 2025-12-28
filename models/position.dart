class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  // Helper para converter para lista (se precisar serializar depois)
  List<int> toTuple() => [row, col];

  @override
  String toString() => 'Position($row, $col)';

  // Necessário para comparar posições corretamente (ex: saber se posA == posB)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Position &&
              runtimeType == other.runtimeType &&
              row == other.row &&
              col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}