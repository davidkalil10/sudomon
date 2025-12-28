class ZoneStructure {
  final int rows;
  final int cols;

  const ZoneStructure(this.rows, this.cols);

  @override
  String toString() => 'ZoneStructure(${rows}x$cols)';
}