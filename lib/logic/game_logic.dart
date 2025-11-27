import '../models/piece.dart';
import '../models/position.dart';
import '../models/game_state.dart';

class Move {
  final Position from;
  final Position to;
  final Position? captured;

  const Move({required this.from, required this.to, this.captured});

  bool get isCapture => captured != null;
}

class GameLogic {
  static List<Move> getValidMoves(GameState state, Position from) {
    final piece = state.pieceAt(from);
    if (piece == null) return [];
    if (piece.color != state.currentTurn) return [];

    final captures = _getCaptureMoves(state, from, piece);
    if (captures.isNotEmpty) return captures;

    // If any piece can capture, must capture (forced capture rule)
    if (_anyPieceCanCapture(state, piece.color)) return [];

    return _getSimpleMoves(state, from, piece);
  }

  static List<Move> _getSimpleMoves(GameState state, Position from, Piece piece) {
    final moves = <Move>[];
    final directions = _getMoveDirections(piece);

    for (final dir in directions) {
      final to = Position(from.row + dir.row, from.col + dir.col);
      if (to.isValid && state.pieceAt(to) == null) {
        moves.add(Move(from: from, to: to));
      }
    }

    return moves;
  }

  static List<Move> _getCaptureMoves(GameState state, Position from, Piece piece) {
    final moves = <Move>[];
    final directions = _getCaptureDirections(piece);

    for (final dir in directions) {
      final over = Position(from.row + dir.row, from.col + dir.col);
      final to = Position(from.row + dir.row * 2, from.col + dir.col * 2);

      if (!to.isValid) continue;

      final overPiece = state.pieceAt(over);
      if (overPiece != null && overPiece.color != piece.color && state.pieceAt(to) == null) {
        moves.add(Move(from: from, to: to, captured: over));
      }
    }

    return moves;
  }

  static bool _anyPieceCanCapture(GameState state, PieceColor color) {
    for (final entry in state.board.entries) {
      if (entry.value.color == color) {
        if (_getCaptureMoves(state, entry.key, entry.value).isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  static List<Position> _getMoveDirections(Piece piece) {
    if (piece.isKing) {
      return const [
        Position(-1, -1), Position(-1, 1),
        Position(1, -1), Position(1, 1),
      ];
    }
    // Black moves down, red moves up
    if (piece.color == PieceColor.black) {
      return const [Position(1, -1), Position(1, 1)];
    } else {
      return const [Position(-1, -1), Position(-1, 1)];
    }
  }

  static List<Position> _getCaptureDirections(Piece piece) {
    // All pieces can capture in all diagonal directions
    if (piece.isKing) {
      return const [
        Position(-1, -1), Position(-1, 1),
        Position(1, -1), Position(1, 1),
      ];
    }
    // Normal pieces can also capture backwards
    return const [
      Position(-1, -1), Position(-1, 1),
      Position(1, -1), Position(1, 1),
    ];
  }

  static GameState makeMove(GameState state, Move move) {
    final newBoard = Map<Position, Piece>.from(state.board);
    var piece = newBoard.remove(move.from)!;

    // Check for promotion
    if (_shouldPromote(piece, move.to)) {
      piece = piece.promote();
    }

    newBoard[move.to] = piece;

    // Remove captured piece
    if (move.captured != null) {
      newBoard.remove(move.captured);
    }

    // Check for additional captures (multi-jump)
    Position? mustContinue;
    if (move.isCapture) {
      final tempState = GameState(
        board: newBoard,
        currentTurn: state.currentTurn,
      );
      final additionalCaptures = _getCaptureMoves(tempState, move.to, piece);
      if (additionalCaptures.isNotEmpty) {
        mustContinue = move.to;
      }
    }

    // Determine next turn
    final nextTurn = mustContinue != null
        ? state.currentTurn
        : (state.currentTurn == PieceColor.black ? PieceColor.red : PieceColor.black);

    var newState = GameState(
      board: newBoard,
      currentTurn: nextTurn,
      mustContinueFrom: mustContinue,
    );

    // Check for win condition
    newState = _checkWinCondition(newState);

    return newState;
  }

  static bool _shouldPromote(Piece piece, Position to) {
    if (piece.isKing) return false;
    if (piece.color == PieceColor.black && to.row == 7) return true;
    if (piece.color == PieceColor.red && to.row == 0) return true;
    return false;
  }

  static GameState _checkWinCondition(GameState state) {
    final blackCount = state.countPieces(PieceColor.black);
    final redCount = state.countPieces(PieceColor.red);

    if (blackCount == 0) {
      return state.copyWith(status: GameStatus.redWins);
    }
    if (redCount == 0) {
      return state.copyWith(status: GameStatus.blackWins);
    }

    // Check if current player has any valid moves
    bool hasValidMoves = false;
    for (final entry in state.board.entries) {
      if (entry.value.color == state.currentTurn) {
        if (getValidMoves(state, entry.key).isNotEmpty) {
          hasValidMoves = true;
          break;
        }
      }
    }

    if (!hasValidMoves) {
      // Player with no moves loses
      return state.copyWith(
        status: state.currentTurn == PieceColor.black
            ? GameStatus.redWins
            : GameStatus.blackWins,
      );
    }

    return state;
  }

  static List<Position> getValidMoveDestinations(GameState state, Position from) {
    return getValidMoves(state, from).map((m) => m.to).toList();
  }

  static Move? findMove(GameState state, Position from, Position to) {
    final moves = getValidMoves(state, from);
    for (final move in moves) {
      if (move.to == to) return move;
    }
    return null;
  }
}
