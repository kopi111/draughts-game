import 'package:flutter/material.dart';
import '../logic/ai_player.dart';
import '../models/piece.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

enum GameMode { twoPlayer, vsComputer, online }

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  GameMode _selectedMode = GameMode.vsComputer;
  Difficulty _selectedDifficulty = Difficulty.medium;
  PieceColor _playerColor = PieceColor.red;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startGame() {
    if (_selectedMode == GameMode.online) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameScreen(
            gameMode: _selectedMode,
            difficulty:
                _selectedMode == GameMode.vsComputer ? _selectedDifficulty : null,
            playerColor:
                _selectedMode == GameMode.vsComputer ? _playerColor : null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildGameModeSection(),
                    if (_selectedMode == GameMode.vsComputer) ...[
                      const SizedBox(height: 32),
                      _buildDifficultySection(),
                      const SizedBox(height: 32),
                      _buildColorSection(),
                    ],
                    const SizedBox(height: 40),
                    _buildStartButton(),
                    const SizedBox(height: 20),
                    _buildBottomButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniPiece(const Color(0xFF2D2D2D)),
            const SizedBox(width: 16),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
              child: const Text(
                'DRAUGHTS',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildMiniPiece(AppTheme.accentPink),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.white10,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
          ),
          child: const Text(
            'CHOOSE YOUR GAME',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.white50,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPiece(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            HSLColor.fromColor(color)
                .withLightness((HSLColor.fromColor(color).lightness + 0.15).clamp(0.0, 1.0))
                .toColor(),
            color,
          ],
          center: const Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: AppTheme.white30, width: 2),
      ),
    );
  }

  Widget _buildGameModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Game Mode', Icons.sports_esports),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModeCard(
                GameMode.vsComputer,
                'VS AI',
                Icons.smart_toy_outlined,
                'Challenge the computer',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeCard(
                GameMode.twoPlayer,
                'LOCAL',
                Icons.people_outline,
                'Play with a friend',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          GameMode.online,
          'ONLINE',
          Icons.public,
          'Play against players worldwide',
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(icon, color: AppTheme.accentCyan, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildModeCard(
    GameMode mode,
    String label,
    IconData icon,
    String description, {
    bool isWide = false,
  }) {
    final isSelected = _selectedMode == mode;
    final borderColor = isSelected ? AppTheme.accentCyan : Colors.transparent;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: AppTheme.animMedium,
        curve: AppTheme.animCurve,
        padding: EdgeInsets.all(isWide ? 20 : 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.accentCyan.withValues(alpha: 0.15),
                    AppTheme.accentCyan.withValues(alpha: 0.05),
                  ],
                )
              : AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected ? AppTheme.glowCyan : null,
        ),
        child: isWide
            ? Row(
                children: [
                  _buildModeIcon(icon, isSelected),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTheme.titleMedium.copyWith(
                            color: isSelected ? AppTheme.white : AppTheme.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          description,
                          style: AppTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.accentCyan,
                      size: 24,
                    ),
                ],
              )
            : Column(
                children: [
                  _buildModeIcon(icon, isSelected),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: AppTheme.titleMedium.copyWith(
                      color: isSelected ? AppTheme.white : AppTheme.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildModeIcon(IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.accentCyan.withValues(alpha: 0.2)
            : AppTheme.white10,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Icon(
        icon,
        color: isSelected ? AppTheme.accentCyan : AppTheme.white50,
        size: 28,
      ),
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Difficulty', Icons.trending_up),
        const SizedBox(height: 16),
        ...Difficulty.values.map((d) => _buildDifficultyCard(d)),
      ],
    );
  }

  Widget _buildDifficultyCard(Difficulty difficulty) {
    final isSelected = _selectedDifficulty == difficulty;
    final color = _getDifficultyColor(difficulty);

    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = difficulty),
      child: AnimatedContainer(
        duration: AppTheme.animMedium,
        curve: AppTheme.animCurve,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                )
              : AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Level badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${difficulty.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.displayName,
                    style: TextStyle(
                      color: isSelected ? AppTheme.white : AppTheme.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    difficulty.description,
                    style: AppTheme.labelSmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.beginner:
        return AppTheme.success;
      case Difficulty.easy:
        return AppTheme.accentCyan;
      case Difficulty.medium:
        return AppTheme.warning;
      case Difficulty.hard:
        return AppTheme.accentPink;
      case Difficulty.expert:
        return AppTheme.error;
    }
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Play As', Icons.palette_outlined),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildColorCard(
                PieceColor.black,
                'Black',
                'Go first',
                const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildColorCard(
                PieceColor.red,
                'Red',
                'Go second',
                AppTheme.accentPink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorCard(
    PieceColor color,
    String label,
    String subtitle,
    Color displayColor,
  ) {
    final isSelected = _playerColor == color;
    final settings = GameSettings();
    final pieceColor = color == PieceColor.black
        ? settings.player1Color
        : settings.player2Color;

    return GestureDetector(
      onTap: () => setState(() => _playerColor = color),
      child: AnimatedContainer(
        duration: AppTheme.animMedium,
        curve: AppTheme.animCurve,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    pieceColor.withValues(alpha: 0.3),
                    pieceColor.withValues(alpha: 0.1),
                  ],
                )
              : AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isSelected ? pieceColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: pieceColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Piece preview
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HSLColor.fromColor(pieceColor)
                        .withLightness(
                            (HSLColor.fromColor(pieceColor).lightness + 0.15)
                                .clamp(0.0, 1.0))
                        .toColor(),
                    pieceColor,
                  ],
                  center: const Alignment(-0.3, -0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: pieceColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: AppTheme.white30, width: 2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.white : AppTheme.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: AppTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPink.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startGame,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'START GAME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildBottomButton(
            icon: Icons.bar_chart_rounded,
            label: 'STATS',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBottomButton(
            icon: Icons.tune_rounded,
            label: 'SETTINGS',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.white50, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
