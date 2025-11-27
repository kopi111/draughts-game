enum PieceType { normal, king }

enum PieceColor { black, red }

class Piece {
  final String id;
  final PieceColor color;
  final PieceType type;

  const Piece({
    required this.id,
    required this.color,
    this.type = PieceType.normal,
  });

  Piece promote() {
    return Piece(id: id, color: color, type: PieceType.king);
  }

  bool get isKing => type == PieceType.king;

  Piece copyWith({PieceColor? color, PieceType? type}) {
    return Piece(
      id: id,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  @override
  String toString() => '${color.name} ${type.name} ($id)';
}
