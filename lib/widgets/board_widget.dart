import 'package:flutter/material.dart';
import '../models/position.dart';
import '../models/game_state.dart';
import 'piece_widget.dart';

class BoardWidget extends StatelessWidget {
  final GameState gameState;
  final Function(Position) onSquareTap;

  const BoardWidget({
    super.key,
    required this.gameState,
    required this.onSquareTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the smaller dimension to make a square board that fills the screen
        final boardSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final squareSize = boardSize / 8;

        return Container(
          color: const Color(0xFF1A1A2E), // Background color for letterboxing
          child: Center(
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: Stack(
                children: [
                  // Board squares
                  _buildBoard(squareSize),
                  // Animated pieces
                  ..._buildAnimatedPieces(squareSize),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard(double squareSize) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        final row = index ~/ 8;
        final col = index % 8;
        final position = Position(row, col);
        return _buildSquare(position, squareSize);
      },
    );
  }

  List<Widget> _buildAnimatedPieces(double squareSize) {
    final pieces = <Widget>[];

    for (final entry in gameState.board.entries) {
      final position = entry.key;
      final piece = entry.value;
      final isSelected = gameState.selectedPosition == position;
      final canSelect = piece.color == gameState.currentTurn &&
          (gameState.mustContinueFrom == null ||
              gameState.mustContinueFrom == position);

      pieces.add(
        AnimatedPositioned(
          key: ValueKey(piece.id), // Use piece ID for smooth animation
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: position.col * squareSize,
          top: position.row * squareSize,
          width: squareSize,
          height: squareSize,
          child: GestureDetector(
            onTap: () => onSquareTap(position),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (value * 0.15),
                    child: Opacity(
                      opacity: canSelect ? 1.0 : 0.6,
                      child: PieceWidget(
                        piece: piece,
                        size: squareSize,
                        isSelected: isSelected,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return pieces;
  }

  Widget _buildSquare(Position position, double squareSize) {
    final isDark = position.isDarkSquare;
    final isSelected = gameState.selectedPosition == position;
    final isValidMove = gameState.validMoves.contains(position);

    // Board colors
    const lightColor = Color(0xFFFED100); // Gold
    const darkColor = Color(0xFF009B3A); // Green

    // Responsive sizes
    final indicatorSize = squareSize * 0.35;
    final borderWidth = squareSize * 0.04;

    return GestureDetector(
      onTap: () => onSquareTap(position),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? darkColor : lightColor,
          border: isSelected
              ? Border.all(color: Colors.white, width: borderWidth)
              : null,
        ),
        child: isValidMove
            ? Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: indicatorSize,
                          height: indicatorSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.8),
                            border: Border.all(color: Colors.white, width: borderWidth),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: squareSize * 0.15,
                                spreadRadius: squareSize * 0.03,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            : null,
      ),
    );
  }
}
