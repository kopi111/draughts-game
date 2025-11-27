import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../models/game_state.dart';
import '../logic/game_logic.dart';
import '../logic/ai_player.dart';
import '../widgets/board_widget.dart';
import 'menu_screen.dart';

class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final Difficulty? difficulty;
  final PieceColor? playerColor;

  const GameScreen({
    super.key,
    this.gameMode = GameMode.twoPlayer,
    this.difficulty,
    this.playerColor,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  AIPlayer? _aiPlayer;
  bool _isAIThinking = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.initial();

    if (widget.gameMode == GameMode.vsComputer && widget.difficulty != null) {
      final aiColor = widget.playerColor == PieceColor.black
          ? PieceColor.red
          : PieceColor.black;
      _aiPlayer = AIPlayer(
        aiColor: aiColor,
        difficulty: widget.difficulty!,
      );

      // If AI plays black, it goes first
      if (aiColor == PieceColor.black) {
        _triggerAIMove();
      }
    }
  }

  bool get _isPlayerTurn {
    if (widget.gameMode == GameMode.twoPlayer) return true;
    return _gameState.currentTurn == widget.playerColor;
  }

  void _triggerAIMove() async {
    if (_aiPlayer == null) return;
    if (_gameState.status != GameStatus.playing) return;
    if (_isPlayerTurn) return;

    setState(() {
      _isAIThinking = true;
    });

    // Quick delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 100));

    final move = await _aiPlayer!.getBestMove(_gameState);

    if (move != null && mounted) {
      setState(() {
        _gameState = GameLogic.makeMove(_gameState, move);
        _gameState = _gameState.copyWith(
          clearSelection: true,
          validMoves: [],
        );
        _isAIThinking = false;
      });

      // Check for win
      if (_gameState.status != GameStatus.playing) {
        _showGameOverDialog();
        return;
      }

      // Check if AI needs to continue (multi-jump)
      if (_gameState.mustContinueFrom != null &&
          _gameState.currentTurn == _aiPlayer!.aiColor) {
        _triggerAIMove();
      }
    } else {
      if (mounted) {
        setState(() {
          _isAIThinking = false;
        });
      }
    }
  }

  void _onSquareTap(Position position) {
    if (_gameState.status != GameStatus.playing) return;
    if (!_isPlayerTurn || _isAIThinking) return;

    final tappedPiece = _gameState.pieceAt(position);

    // If there's a must-continue situation
    if (_gameState.mustContinueFrom != null) {
      if (position == _gameState.mustContinueFrom) {
        // Tapping the piece that must continue - show valid moves
        final validMoves = GameLogic.getValidMoveDestinations(_gameState, position);
        setState(() {
          _gameState = _gameState.copyWith(
            selectedPosition: position,
            validMoves: validMoves,
          );
        });
      } else if (_gameState.validMoves.contains(position)) {
        // Making the forced move
        _makeMove(_gameState.mustContinueFrom!, position);
      }
      return;
    }

    // If clicking on a valid move destination
    if (_gameState.selectedPosition != null &&
        _gameState.validMoves.contains(position)) {
      _makeMove(_gameState.selectedPosition!, position);
      return;
    }

    // If clicking on own piece, select it
    if (tappedPiece != null && tappedPiece.color == _gameState.currentTurn) {
      final validMoves = GameLogic.getValidMoveDestinations(_gameState, position);
      setState(() {
        _gameState = _gameState.copyWith(
          selectedPosition: position,
          validMoves: validMoves,
        );
      });
      return;
    }

    // Clicking elsewhere - deselect
    setState(() {
      _gameState = _gameState.copyWith(
        clearSelection: true,
        validMoves: [],
      );
    });
  }

  void _makeMove(Position from, Position to) {
    final move = GameLogic.findMove(_gameState, from, to);
    if (move == null) return;

    setState(() {
      _gameState = GameLogic.makeMove(_gameState, move);
      _gameState = _gameState.copyWith(
        clearSelection: true,
        validMoves: [],
      );

      // If there's a must-continue, auto-select that piece
      if (_gameState.mustContinueFrom != null) {
        final validMoves = GameLogic.getValidMoveDestinations(
          _gameState,
          _gameState.mustContinueFrom!,
        );
        _gameState = _gameState.copyWith(
          selectedPosition: _gameState.mustContinueFrom,
          validMoves: validMoves,
        );
      }
    });

    // Show win dialog if game ended
    if (_gameState.status != GameStatus.playing) {
      _showGameOverDialog();
      return;
    }

    // Trigger AI move if it's computer's turn
    if (!_isPlayerTurn && _aiPlayer != null) {
      _triggerAIMove();
    }
  }

  void _showGameOverDialog() {
    final winner = _gameState.status == GameStatus.blackWins ? 'Black' : 'Red';
    final winnerColor = _gameState.status == GameStatus.blackWins
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFC41E3A);

    String message;
    if (widget.gameMode == GameMode.vsComputer) {
      final playerWon = (_gameState.status == GameStatus.blackWins &&
              widget.playerColor == PieceColor.black) ||
          (_gameState.status == GameStatus.redWins &&
              widget.playerColor == PieceColor.red);
      message = playerWon ? 'Congratulations! You won!' : 'The computer wins!';
    } else {
      message = 'Congratulations! $winner has won the game.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            Text(
              '$winner Wins!',
              style: TextStyle(color: winnerColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to menu
            },
            child: const Text('Back to Menu'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _gameState = GameState.initial();
    });

    // If AI plays black, trigger AI move
    if (_aiPlayer != null && _aiPlayer!.aiColor == PieceColor.black) {
      _triggerAIMove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = _gameState.currentTurn == PieceColor.black ? 'Black' : 'Red';
    final playerColor = _gameState.currentTurn == PieceColor.black
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFC41E3A);

    String turnText;
    if (widget.gameMode == GameMode.vsComputer) {
      if (_isAIThinking) {
        turnText = 'Computer is thinking...';
      } else if (_isPlayerTurn) {
        turnText = _gameState.mustContinueFrom != null
            ? 'You must continue jumping!'
            : 'Your Turn';
      } else {
        turnText = "Computer's Turn";
      }
    } else {
      turnText = _gameState.mustContinueFrom != null
          ? '$currentPlayer must continue jumping!'
          : "$currentPlayer's Turn";
    }

    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final shortestSide = screenSize.shortestSide;

    // Responsive sizes based on screen
    final buttonSize = shortestSide * 0.12;
    final iconSize = shortestSide * 0.06;
    final fontSize = shortestSide * 0.035;
    final indicatorSize = shortestSide * 0.035;

    return Scaffold(
      body: Stack(
        children: [
          // Full screen game board
          Positioned.fill(
            child: BoardWidget(
              gameState: _gameState,
              onSquareTap: _onSquareTap,
            ),
          ),

          // Overlay UI - back button (top left)
          Positioned(
            top: padding.top + 8,
            left: 8,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(buttonSize * 0.2),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Overlay UI - reset button (top right)
          Positioned(
            top: padding.top + 8,
            right: 8,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(buttonSize * 0.2),
              ),
              child: IconButton(
                icon: Icon(Icons.refresh, color: Colors.white, size: iconSize),
                onPressed: _resetGame,
                tooltip: 'New Game',
              ),
            ),
          ),

          // Turn indicator (bottom center)
          Positioned(
            bottom: padding.bottom + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: shortestSide * 0.05,
                  vertical: shortestSide * 0.025,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(shortestSide * 0.05),
                  border: Border.all(color: playerColor, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isAIThinking)
                      SizedBox(
                        width: indicatorSize,
                        height: indicatorSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Container(
                        width: indicatorSize,
                        height: indicatorSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: playerColor,
                        ),
                      ),
                    SizedBox(width: shortestSide * 0.02),
                    Text(
                      turnText,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, int count, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.6 : 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.white : color,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
