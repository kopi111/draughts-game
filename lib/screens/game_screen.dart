import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../models/game_state.dart';
import '../logic/game_logic.dart';
import '../logic/ai_player.dart';
import '../widgets/board_widget.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import '../services/stats_service.dart';
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

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameState _gameState;
  AIPlayer? _aiPlayer;
  bool _isAIThinking = false;
  final AudioService _audio = AudioService();
  final StatsService _stats = StatsService();

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.initial();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    if (widget.gameMode == GameMode.vsComputer && widget.difficulty != null) {
      final aiColor = widget.playerColor == PieceColor.black
          ? PieceColor.red
          : PieceColor.black;
      _aiPlayer = AIPlayer(
        aiColor: aiColor,
        difficulty: widget.difficulty!,
      );

      if (aiColor == PieceColor.black) {
        _triggerAIMove();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isPlayerTurn {
    if (widget.gameMode == GameMode.twoPlayer) return true;
    return _gameState.currentTurn == widget.playerColor;
  }

  void _triggerAIMove() async {
    if (_aiPlayer == null) return;
    if (_gameState.status != GameStatus.playing) return;
    if (_isPlayerTurn) return;

    setState(() => _isAIThinking = true);

    await Future.delayed(const Duration(milliseconds: 300));

    final move = await _aiPlayer!.getBestMove(_gameState);

    if (move != null && mounted) {
      final wasCapture = move.isCapture;

      setState(() {
        _gameState = GameLogic.makeMove(_gameState, move);
        _gameState = _gameState.copyWith(clearSelection: true, validMoves: []);
        _isAIThinking = false;
      });

      if (wasCapture) {
        _audio.playCapture();
        _audio.vibrateMedium();
        _stats.recordCapture();
      } else {
        _audio.playMove();
        _audio.vibrateLight();
      }

      if (_gameState.status != GameStatus.playing) {
        _handleGameEnd();
        return;
      }

      if (_gameState.mustContinueFrom != null &&
          _gameState.currentTurn == _aiPlayer!.aiColor) {
        _triggerAIMove();
      }
    } else {
      if (mounted) setState(() => _isAIThinking = false);
    }
  }

  void _onSquareTap(Position position) {
    if (_gameState.status != GameStatus.playing) return;
    if (!_isPlayerTurn || _isAIThinking) return;

    final tappedPiece = _gameState.pieceAt(position);

    if (_gameState.mustContinueFrom != null) {
      if (position == _gameState.mustContinueFrom) {
        final validMoves =
            GameLogic.getValidMoveDestinations(_gameState, position);
        setState(() {
          _gameState = _gameState.copyWith(
            selectedPosition: position,
            validMoves: validMoves,
          );
        });
        _audio.playSelect();
      } else if (_gameState.validMoves.contains(position)) {
        _makeMove(_gameState.mustContinueFrom!, position);
      }
      return;
    }

    if (_gameState.selectedPosition != null &&
        _gameState.validMoves.contains(position)) {
      _makeMove(_gameState.selectedPosition!, position);
      return;
    }

    if (tappedPiece != null && tappedPiece.color == _gameState.currentTurn) {
      final validMoves =
          GameLogic.getValidMoveDestinations(_gameState, position);
      setState(() {
        _gameState = _gameState.copyWith(
          selectedPosition: position,
          validMoves: validMoves,
        );
      });
      _audio.playSelect();
      _audio.vibrateLight();
      return;
    }

    setState(() {
      _gameState = _gameState.copyWith(clearSelection: true, validMoves: []);
    });
  }

  void _makeMove(Position from, Position to) {
    final move = GameLogic.findMove(_gameState, from, to);
    if (move == null) return;

    final wasCapture = move.isCapture;
    final pieceBeforeMove = _gameState.pieceAt(from);

    setState(() {
      _gameState = GameLogic.makeMove(_gameState, move);
      _gameState = _gameState.copyWith(clearSelection: true, validMoves: []);

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

    // Check for king promotion
    final pieceAfterMove = _gameState.pieceAt(to);
    if (pieceBeforeMove != null &&
        pieceAfterMove != null &&
        !pieceBeforeMove.isKing &&
        pieceAfterMove.isKing) {
      _audio.playKing();
      _audio.vibrateHeavy();
      _stats.recordKing();
    } else if (wasCapture) {
      _audio.playCapture();
      _audio.vibrateMedium();
      _stats.recordCapture();
    } else {
      _audio.playMove();
      _audio.vibrateLight();
    }

    if (_gameState.status != GameStatus.playing) {
      _handleGameEnd();
      return;
    }

    if (!_isPlayerTurn && _aiPlayer != null) {
      _triggerAIMove();
    }
  }

  void _handleGameEnd() {
    final playerWon = (widget.gameMode == GameMode.vsComputer) &&
        ((_gameState.status == GameStatus.blackWins &&
                widget.playerColor == PieceColor.black) ||
            (_gameState.status == GameStatus.redWins &&
                widget.playerColor == PieceColor.red));

    if (widget.gameMode == GameMode.vsComputer) {
      if (playerWon) {
        _audio.playWin();
        _stats.recordWin(difficulty: widget.difficulty);
      } else {
        _audio.playLose();
        _stats.recordLoss(difficulty: widget.difficulty);
      }
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _showGameOverDialog();
    });
  }

  void _showGameOverDialog() {
    final isBlackWin = _gameState.status == GameStatus.blackWins;
    final winner = isBlackWin ? 'Black' : 'Red';
    final winnerColor = isBlackWin ? const Color(0xFF2D2D2D) : AppTheme.accentPink;

    bool playerWon = false;
    String message;

    if (widget.gameMode == GameMode.vsComputer) {
      playerWon = (isBlackWin && widget.playerColor == PieceColor.black) ||
          (!isBlackWin && widget.playerColor == PieceColor.red);
      message = playerWon
          ? 'Congratulations! You defeated the AI!'
          : 'The computer wins this round. Try again!';
    } else {
      message = '$winner player wins the game!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: winnerColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: winnerColor.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: winnerColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playerWon ? Icons.emoji_events : Icons.sports_esports,
                  color: playerWon ? AppTheme.accentGold : winnerColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [winnerColor, AppTheme.accentGold],
                ).createShader(bounds),
                child: Text(
                  playerWon ? 'VICTORY!' : '$winner Wins!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      'Menu',
                      Icons.home_rounded,
                      AppTheme.white30,
                      () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDialogButton(
                      'Rematch',
                      Icons.refresh_rounded,
                      winnerColor,
                      () {
                        Navigator.of(context).pop();
                        _resetGame();
                      },
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
            : null,
        color: isPrimary ? null : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _gameState = GameState.initial();
    });

    if (_aiPlayer != null && _aiPlayer!.aiColor == PieceColor.black) {
      _triggerAIMove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer =
        _gameState.currentTurn == PieceColor.black ? 'Black' : 'Red';
    final playerColor = _gameState.currentTurn == PieceColor.black
        ? const Color(0xFF2D2D2D)
        : AppTheme.accentPink;

    final blackCount = _gameState.countPieces(PieceColor.black);
    final redCount = _gameState.countPieces(PieceColor.red);

    String turnText;
    if (widget.gameMode == GameMode.vsComputer) {
      if (_isAIThinking) {
        turnText = 'AI is thinking...';
      } else if (_isPlayerTurn) {
        turnText = _gameState.mustContinueFrom != null
            ? 'Continue jumping!'
            : 'Your Turn';
      } else {
        turnText = "AI's Turn";
      }
    } else {
      turnText = _gameState.mustContinueFrom != null
          ? '$currentPlayer must jump!'
          : "$currentPlayer's Turn";
    }

    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // Game board
            Center(
              child: BoardWidget(
                gameState: _gameState,
                onSquareTap: _onSquareTap,
              ),
            ),

            // Top bar
            Positioned(
              top: padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(
                    Icons.arrow_back_rounded,
                    () => Navigator.of(context).pop(),
                  ),
                  _buildScoreIndicator(blackCount, redCount),
                  _buildIconButton(Icons.refresh_rounded, _resetGame),
                ],
              ),
            ),

            // Turn indicator
            Positioned(
              bottom: padding.bottom + 24,
              left: 24,
              right: 24,
              child: _buildTurnIndicator(turnText, playerColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: AppTheme.white70, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(int blackCount, int redCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: AppTheme.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPieceCount(const Color(0xFF2D2D2D), blackCount),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 2,
            height: 24,
            color: AppTheme.white10,
          ),
          _buildPieceCount(AppTheme.accentPink, redCount),
        ],
      ),
    );
  }

  Widget _buildPieceCount(Color color, int count) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                HSLColor.fromColor(color)
                    .withLightness(
                        (HSLColor.fromColor(color).lightness + 0.15).clamp(0.0, 1.0))
                    .toColor(),
                color,
              ],
            ),
            border: Border.all(color: AppTheme.white30, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildTurnIndicator(String text, Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _isAIThinking ? (0.5 + _pulseController.value * 0.5) : 1.0;
        return Opacity(
          opacity: pulse,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAIThinking)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
