import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  late Animation<double> _slideUp;
  late Animation<double> _pieceSlide;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Continuous pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Continuous rotation for decorative elements
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Fade in animation
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Scale up animation
    _scaleUp = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Slide up animation
    _slideUp = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Piece slide animation
    _pieceSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _mainController.forward();

    // Navigate to menu
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MenuScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // Animated background circles
            _buildBackgroundDecorations(size),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: Opacity(
                      opacity: _fadeIn.value,
                      child: Transform.scale(
                        scale: _scaleUp.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo with animated pieces
                            _buildLogo(),
                            const SizedBox(height: 48),

                            // Title
                            _buildTitle(),
                            const SizedBox(height: 16),

                            // Subtitle
                            _buildSubtitle(),
                            const SizedBox(height: 64),

                            // Loading indicator
                            _buildLoadingIndicator(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations(Size size) {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top-left glow
            Positioned(
              top: -100,
              left: -100,
              child: Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentCyan.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-right glow
            Positioned(
              bottom: -150,
              right: -150,
              child: Transform.rotate(
                angle: -_rotateController.value * 2 * math.pi,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentPink.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Center subtle glow
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 200 + (_pulseController.value * 50),
                    height: 200 + (_pulseController.value * 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentGold.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pieceSlide,
      builder: (context, child) {
        return SizedBox(
          width: 160,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Black piece - slides from left
              Positioned(
                left: 0 + (20 * _pieceSlide.value),
                child: _buildPiece(
                  color: const Color(0xFF2D2D2D),
                  highlight: const Color(0xFF4A4A4A),
                  size: 70,
                  showCrown: true,
                ),
              ),
              // Red piece - slides from right
              Positioned(
                right: 0 + (20 * _pieceSlide.value),
                child: _buildPiece(
                  color: AppTheme.accentPink,
                  highlight: const Color(0xFFFF6B8A),
                  size: 70,
                  showCrown: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPiece({
    required Color color,
    required Color highlight,
    required double size,
    required bool showCrown,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [highlight, color],
                center: const Alignment(-0.3, -0.3),
                radius: 0.8,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: showCrown
                ? Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppTheme.accentGold,
                      size: size * 0.4,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          AppTheme.accentCyan,
          AppTheme.white,
          AppTheme.accentPink,
        ],
      ).createShader(bounds),
      child: const Text(
        'DRAUGHTS',
        style: TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 8,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.white10,
            AppTheme.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: AppTheme.white10),
      ),
      child: const Text(
        'CLASSIC CHECKERS',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.white70,
          letterSpacing: 6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          children: [
            // Custom loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final progress =
                    ((_pulseController.value + delay) % 1.0).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentCyan.withValues(alpha: 0.3 + (progress * 0.7)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentCyan.withValues(alpha: progress * 0.5),
                        blurRadius: 8,
                        spreadRadius: progress * 2,
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.white.withValues(alpha: 0.4),
                letterSpacing: 2,
              ),
            ),
          ],
        );
      },
    );
  }
}
