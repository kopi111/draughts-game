class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  bool get isValid => row >= 0 && row < 8 && col >= 0 && col < 8;

  bool get isDarkSquare => (row + col) % 2 == 1;

  Position operator +(Position other) => Position(row + other.row, col + other.col);

  Position operator -(Position other) => Position(row - other.row, col - other.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';
}
