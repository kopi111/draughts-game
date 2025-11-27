import 'piece.dart';
import 'position.dart';

enum GameStatus { playing, blackWins, redWins, draw }

class GameState {
  final Map<Position, Piece> board;
  final PieceColor currentTurn;
  final Position? selectedPosition;
  final List<Position> validMoves;
  final GameStatus status;
  final Position? mustContinueFrom;

  const GameState({
    required this.board,
    this.currentTurn = PieceColor.black,
    this.selectedPosition,
    this.validMoves = const [],
    this.status = GameStatus.playing,
    this.mustContinueFrom,
  });

  factory GameState.initial() {
    final board = <Position, Piece>{};
    int pieceId = 0;

    // Place black pieces (top 3 rows)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board[Position(row, col)] = Piece(
            id: 'b${pieceId++}',
            color: PieceColor.black,
          );
        }
      }
    }

    // Place red pieces (bottom 3 rows)
    for (int row = 5; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board[Position(row, col)] = Piece(
            id: 'r${pieceId++}',
            color: PieceColor.red,
          );
        }
      }
    }

    return GameState(board: board);
  }

  Piece? pieceAt(Position pos) => board[pos];

  int countPieces(PieceColor color) {
    return board.values.where((p) => p.color == color).length;
  }

  GameState copyWith({
    Map<Position, Piece>? board,
    PieceColor? currentTurn,
    Position? selectedPosition,
    List<Position>? validMoves,
    GameStatus? status,
    Position? mustContinueFrom,
    bool clearSelection = false,
    bool clearMustContinue = false,
  }) {
    return GameState(
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      selectedPosition: clearSelection ? null : (selectedPosition ?? this.selectedPosition),
      validMoves: validMoves ?? this.validMoves,
      status: status ?? this.status,
      mustContinueFrom: clearMustContinue ? null : (mustContinueFrom ?? this.mustContinueFrom),
    );
  }
}
