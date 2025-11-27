import 'dart:math';
import '../models/piece.dart';
import '../models/game_state.dart';
import 'game_logic.dart';

enum Difficulty {
  beginner,    // Level 1: Random moves
  easy,        // Level 2: Depth 1
  medium,      // Level 3: Depth 3
  hard,        // Level 4: Depth 5
  expert,      // Level 5: Depth 7
}

extension DifficultyExtension on Difficulty {
  String get displayName {
    switch (this) {
      case Difficulty.beginner:
        return 'Beginner';
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  String get description {
    switch (this) {
      case Difficulty.beginner:
        return 'Random moves - perfect for learning';
      case Difficulty.easy:
        return 'Thinks 1 move ahead';
      case Difficulty.medium:
        return 'Thinks 3 moves ahead';
      case Difficulty.hard:
        return 'Thinks 5 moves ahead';
      case Difficulty.expert:
        return 'Thinks 7 moves ahead - very challenging!';
    }
  }

  int get searchDepth {
    switch (this) {
      case Difficulty.beginner:
        return 0;
      case Difficulty.easy:
        return 1;
      case Difficulty.medium:
        return 3;
      case Difficulty.hard:
        return 5;
      case Difficulty.expert:
        return 7;
    }
  }
}

class AIPlayer {
  final PieceColor aiColor;
  final Difficulty difficulty;
  final Random _random = Random();

  AIPlayer({
    required this.aiColor,
    required this.difficulty,
  });

  /// Gets the best move for the AI
  Future<Move?> getBestMove(GameState state) async {
    if (state.currentTurn != aiColor) return null;
    if (state.status != GameStatus.playing) return null;

    final allMoves = _getAllValidMoves(state, aiColor);
    if (allMoves.isEmpty) return null;

    // Beginner level: random moves
    if (difficulty == Difficulty.beginner) {
      return allMoves[_random.nextInt(allMoves.length)];
    }

    // Use minimax with alpha-beta pruning for other levels
    Move? bestMove;
    int bestScore = -100000;
    int alpha = -100000;
    int beta = 100000;

    // Shuffle moves to add some randomness when moves have equal scores
    allMoves.shuffle(_random);

    for (final move in allMoves) {
      final newState = GameLogic.makeMove(state, move);
      final score = _minimax(
        newState,
        difficulty.searchDepth - 1,
        alpha,
        beta,
        false,
      );

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
      alpha = max(alpha, score);
    }

    return bestMove;
  }

  int _minimax(GameState state, int depth, int alpha, int beta, bool isMaximizing) {
    // Terminal conditions
    if (depth == 0 || state.status != GameStatus.playing) {
      return _evaluateBoard(state);
    }

    final currentColor = isMaximizing ? aiColor : _opponentColor;
    final moves = _getAllValidMoves(state, currentColor);

    if (moves.isEmpty) {
      // No moves available means this player loses
      return isMaximizing ? -10000 : 10000;
    }

    if (isMaximizing) {
      int maxEval = -100000;
      for (final move in moves) {
        final newState = GameLogic.makeMove(state, move);
        // If it's still the same player's turn (multi-jump), keep maximizing
        final stillMaximizing = newState.currentTurn == aiColor;
        final eval = _minimax(newState, depth - 1, alpha, beta, stillMaximizing);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 100000;
      for (final move in moves) {
        final newState = GameLogic.makeMove(state, move);
        // If it's still the same player's turn (multi-jump), keep minimizing
        final stillMinimizing = newState.currentTurn == _opponentColor;
        final eval = _minimax(newState, depth - 1, alpha, beta, !stillMinimizing);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  PieceColor get _opponentColor =>
      aiColor == PieceColor.black ? PieceColor.red : PieceColor.black;

  int _evaluateBoard(GameState state) {
    // Check for win/loss
    if (state.status == GameStatus.blackWins) {
      return aiColor == PieceColor.black ? 10000 : -10000;
    }
    if (state.status == GameStatus.redWins) {
      return aiColor == PieceColor.red ? 10000 : -10000;
    }

    int score = 0;

    for (final entry in state.board.entries) {
      final piece = entry.value;
      final position = entry.key;
      final isAI = piece.color == aiColor;
      final multiplier = isAI ? 1 : -1;

      // Base piece value
      int pieceValue = piece.isKing ? 50 : 30;

      // Position bonuses
      // Center control bonus
      final centerDistance = (3.5 - position.col).abs() + (3.5 - position.row).abs();
      pieceValue += (7 - centerDistance.toInt());

      // Advancement bonus for non-kings
      if (!piece.isKing) {
        if (piece.color == PieceColor.black) {
          pieceValue += position.row * 2; // Reward advancing down
        } else {
          pieceValue += (7 - position.row) * 2; // Reward advancing up
        }
      }

      // Back row protection bonus (for non-kings, staying on back row)
      if (!piece.isKing) {
        if (piece.color == PieceColor.black && position.row == 0) {
          pieceValue += 5;
        } else if (piece.color == PieceColor.red && position.row == 7) {
          pieceValue += 5;
        }
      }

      // King mobility bonus
      if (piece.isKing) {
        final kingMoves = GameLogic.getValidMoves(state, position);
        pieceValue += kingMoves.length * 2;
      }

      score += pieceValue * multiplier;
    }

    // Piece count difference
    final aiPieces = state.countPieces(aiColor);
    final opponentPieces = state.countPieces(_opponentColor);
    score += (aiPieces - opponentPieces) * 100;

    return score;
  }

  List<Move> _getAllValidMoves(GameState state, PieceColor color) {
    final moves = <Move>[];

    // If there's a must-continue position, only get moves from there
    if (state.mustContinueFrom != null) {
      return GameLogic.getValidMoves(state, state.mustContinueFrom!);
    }

    for (final entry in state.board.entries) {
      if (entry.value.color == color) {
        moves.addAll(GameLogic.getValidMoves(state, entry.key));
      }
    }

    return moves;
  }
}
