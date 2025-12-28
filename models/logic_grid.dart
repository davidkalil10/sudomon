import 'grid_cell.dart';
import 'grid_solution.dart';

class LogicGrid {
  final List<List<GridCell>> grid;
  final GridSolution solution;

  LogicGrid(this.grid, this.solution);

  GridCell getCell(int row, int col) => grid[row][col];
}