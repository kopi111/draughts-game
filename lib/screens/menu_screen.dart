import 'package:flutter/material.dart';
import '../logic/ai_player.dart';
import '../models/piece.dart';
import 'game_screen.dart';

enum GameMode { twoPlayer, vsComputer }

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  GameMode _selectedMode = GameMode.vsComputer;
  Difficulty _selectedDifficulty = Difficulty.medium;
  PieceColor _playerColor = PieceColor.red; // Player plays as red (bottom)

  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          gameMode: _selectedMode,
          difficulty: _selectedMode == GameMode.vsComputer ? _selectedDifficulty : null,
          playerColor: _selectedMode == GameMode.vsComputer ? _playerColor : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E), // Deep navy
              Color(0xFF16213E), // Dark blue
              Color(0xFF0F3460), // Rich blue
              Color(0xFF1A1A2E), // Deep navy
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Title with elegant gradient
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF00D9FF), // Cyan
                        Color(0xFFE94560), // Pink/Red accent
                        Color(0xFF00D9FF), // Cyan
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'DRAUGHTS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 8,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Classic Checkers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Game Mode Selection
                  _buildSectionTitle('Game Mode'),
                  const SizedBox(height: 12),
                  _buildModeSelector(),
                  const SizedBox(height: 28),

                  // Difficulty Selection (only for vs Computer)
                  if (_selectedMode == GameMode.vsComputer) ...[
                    _buildSectionTitle('Difficulty Level'),
                    const SizedBox(height: 12),
                    _buildDifficultySelector(),
                    const SizedBox(height: 28),

                    // Color Selection
                    _buildSectionTitle('Play As'),
                    const SizedBox(height: 12),
                    _buildColorSelector(),
                    const SizedBox(height: 28),
                  ],

                  const SizedBox(height: 20),

                  // Start Button
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE94560),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'START GAME',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildModeCard(
            GameMode.vsComputer,
            'vs Computer',
            Icons.computer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModeCard(
            GameMode.twoPlayer,
            '2 Players',
            Icons.people,
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard(GameMode mode, String label, IconData icon) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00D9FF).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? const Color(0xFF00D9FF) : Colors.white70,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      children: Difficulty.values.map((difficulty) {
        final isSelected = _selectedDifficulty == difficulty;
        final levelNumber = difficulty.index + 1;
        return GestureDetector(
          onTap: () => setState(() => _selectedDifficulty = difficulty),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? _getDifficultyColor(difficulty).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _getDifficultyColor(difficulty)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Level indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(difficulty),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$levelNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        difficulty.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        difficulty.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00D9FF),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.beginner:
        return const Color(0xFF4CAF50); // Green
      case Difficulty.easy:
        return const Color(0xFF00D9FF); // Cyan
      case Difficulty.medium:
        return const Color(0xFFFFB74D); // Amber
      case Difficulty.hard:
        return const Color(0xFFE94560); // Pink/Red
      case Difficulty.expert:
        return const Color(0xFFD32F2F); // Dark red
    }
  }

  Widget _buildColorSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildColorCard(PieceColor.red, 'Red', 'You go second'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildColorCard(PieceColor.black, 'Black', 'You go first'),
        ),
      ],
    );
  }

  Widget _buildColorCard(PieceColor color, String label, String subtitle) {
    final isSelected = _playerColor == color;
    final displayColor = color == PieceColor.black
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFC41E3A);

    return GestureDetector(
      onTap: () => setState(() => _playerColor = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? displayColor.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? displayColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: displayColor,
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: displayColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
