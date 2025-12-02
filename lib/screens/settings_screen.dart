import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final GameSettings _settings = GameSettings();
  final AudioService _audio = AudioService();

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildAudioSection(),
                      const SizedBox(height: 28),
                      _buildBoardThemeSection(),
                      const SizedBox(height: 28),
                      _buildPieceThemeSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildResetButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.arrow_back_rounded, color: AppTheme.white70),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _settings.resetToDefaults();
            setState(() {});
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded, color: AppTheme.white50, size: 18),
                const SizedBox(width: 8),
                Text('Reset', style: AppTheme.labelSmall.copyWith(color: AppTheme.white50)),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildAudioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Sound & Haptics', Icons.volume_up_rounded),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassCard,
          child: Column(
            children: [
              _buildToggleRow(
                icon: Icons.music_note_rounded,
                title: 'Sound Effects',
                subtitle: 'Play sounds on moves and captures',
                value: _audio.soundEnabled,
                onChanged: (value) async {
                  await _audio.setSoundEnabled(value);
                  setState(() {});
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppTheme.white10, height: 1),
              ),
              _buildToggleRow(
                icon: Icons.vibration_rounded,
                title: 'Vibration',
                subtitle: 'Haptic feedback on actions',
                value: _audio.vibrationEnabled,
                onChanged: (value) async {
                  await _audio.setVibrationEnabled(value);
                  if (value) _audio.vibrateLight();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: value
                ? AppTheme.success.withValues(alpha: 0.2)
                : AppTheme.white10,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            icon,
            color: value ? AppTheme.success : AppTheme.white50,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.titleMedium),
              Text(subtitle, style: AppTheme.labelSmall),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.success,
          activeTrackColor: AppTheme.success.withValues(alpha: 0.3),
          inactiveThumbColor: AppTheme.white50,
          inactiveTrackColor: AppTheme.white10,
        ),
      ],
    );
  }

  Widget _buildBoardThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Board Theme', Icons.grid_view_rounded),
        const SizedBox(height: 16),
        _buildBoardPreview(),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: GameSettings.boardThemes.length,
          itemBuilder: (context, index) {
            final theme = GameSettings.boardThemes[index];
            final isSelected =
                _settings.lightSquareColor == theme.lightColor &&
                    _settings.darkSquareColor == theme.darkColor;
            return _buildBoardThemeCard(theme, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildBoardPreview() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.shadowMedium,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Row(
          children: List.generate(8, (col) {
            return Expanded(
              child: Column(
                children: List.generate(2, (row) {
                  final isDark = (row + col) % 2 == 1;
                  return Expanded(
                    child: Container(
                      color: isDark
                          ? _settings.darkSquareColor
                          : _settings.lightSquareColor,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBoardThemeCard(BoardTheme theme, bool isSelected) {
    return GestureDetector(
      onTap: () async {
        await _settings.setBoardTheme(theme);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: AppTheme.animMedium,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected ? AppTheme.accentGold : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? AppTheme.glowGold : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusM - 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: Container(color: theme.lightColor)),
                          Expanded(child: Container(color: theme.darkColor)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: Container(color: theme.darkColor)),
                          Expanded(child: Container(color: theme.lightColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentGold.withValues(alpha: 0.2)
                    : AppTheme.primaryDark,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusM - 2),
                ),
              ),
              child: Text(
                theme.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppTheme.accentGold : AppTheme.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieceThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Piece Colors', Icons.circle),
        const SizedBox(height: 16),
        _buildPiecePreview(),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: GameSettings.pieceThemes.length,
          itemBuilder: (context, index) {
            final theme = GameSettings.pieceThemes[index];
            final isSelected =
                _settings.player1Color == theme.player1Color &&
                    _settings.player2Color == theme.player2Color;
            return _buildPieceThemeCard(theme, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildPiecePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: AppTheme.glassCard,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPiecePreviewItem('Player 1', _settings.player1Color),
          Container(width: 1, height: 50, color: AppTheme.white10),
          _buildPiecePreviewItem('Player 2', _settings.player2Color),
        ],
      ),
    );
  }

  Widget _buildPiecePreviewItem(String label, Color color) {
    final highlightColor = HSLColor.fromColor(color)
        .withLightness(
            (HSLColor.fromColor(color).lightness + 0.2).clamp(0.0, 1.0))
        .toColor();

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [highlightColor, color],
              center: const Alignment(-0.3, -0.3),
              radius: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: AppTheme.white30, width: 2),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: AppTheme.labelSmall),
      ],
    );
  }

  Widget _buildPieceThemeCard(PieceTheme theme, bool isSelected) {
    return GestureDetector(
      onTap: () async {
        await _settings.setPieceTheme(theme);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: AppTheme.animMedium,
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected ? AppTheme.accentGold : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? AppTheme.glowGold : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniPiece(theme.player1Color),
                  _buildMiniPiece(theme.player2Color),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentGold.withValues(alpha: 0.2)
                    : AppTheme.primaryDark.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusM - 2),
                ),
              ),
              child: Text(
                theme.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppTheme.accentGold : AppTheme.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPiece(Color color) {
    final highlightColor = HSLColor.fromColor(color)
        .withLightness(
            (HSLColor.fromColor(color).lightness + 0.2).clamp(0.0, 1.0))
        .toColor();

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [highlightColor, color],
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
        border: Border.all(color: AppTheme.white30, width: 1.5),
      ),
    );
  }
}
