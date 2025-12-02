import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameSettings extends ChangeNotifier {
  static final GameSettings _instance = GameSettings._internal();
  factory GameSettings() => _instance;
  GameSettings._internal();

  SharedPreferences? _prefs;

  // Default colors
  static const Color defaultLightSquare = Color(0xFFFED100); // Gold
  static const Color defaultDarkSquare = Color(0xFF009B3A); // Green
  static const Color defaultPlayer1Color = Color(0xFF1A1A1A); // Black
  static const Color defaultPlayer2Color = Color(0xFFC41E3A); // Red

  // Current colors
  Color _lightSquareColor = defaultLightSquare;
  Color _darkSquareColor = defaultDarkSquare;
  Color _player1Color = defaultPlayer1Color;
  Color _player2Color = defaultPlayer2Color;

  // Getters
  Color get lightSquareColor => _lightSquareColor;
  Color get darkSquareColor => _darkSquareColor;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;

  // Preset board themes
  static final List<BoardTheme> boardThemes = [
    BoardTheme(
      name: 'Jamaica',
      lightColor: const Color(0xFFFED100),
      darkColor: const Color(0xFF009B3A),
    ),
    BoardTheme(
      name: 'Classic',
      lightColor: const Color(0xFFF0D9B5),
      darkColor: const Color(0xFFB58863),
    ),
    BoardTheme(
      name: 'Blue',
      lightColor: const Color(0xFFDEE3E6),
      darkColor: const Color(0xFF5882A6),
    ),
    BoardTheme(
      name: 'Green',
      lightColor: const Color(0xFFEEEED2),
      darkColor: const Color(0xFF769656),
    ),
    BoardTheme(
      name: 'Purple',
      lightColor: const Color(0xFFE8D5E8),
      darkColor: const Color(0xFF7B4397),
    ),
    BoardTheme(
      name: 'Ocean',
      lightColor: const Color(0xFFB8D4E3),
      darkColor: const Color(0xFF0077B6),
    ),
    BoardTheme(
      name: 'Sunset',
      lightColor: const Color(0xFFFFE5B4),
      darkColor: const Color(0xFFFF6B35),
    ),
    BoardTheme(
      name: 'Midnight',
      lightColor: const Color(0xFF4A4A6A),
      darkColor: const Color(0xFF1A1A2E),
    ),
  ];

  // Preset piece themes
  static final List<PieceTheme> pieceThemes = [
    PieceTheme(
      name: 'Classic',
      player1Color: const Color(0xFF1A1A1A),
      player2Color: const Color(0xFFC41E3A),
    ),
    PieceTheme(
      name: 'Blue vs Orange',
      player1Color: const Color(0xFF1E3A5F),
      player2Color: const Color(0xFFFF6B35),
    ),
    PieceTheme(
      name: 'Purple vs Gold',
      player1Color: const Color(0xFF4A148C),
      player2Color: const Color(0xFFFFD700),
    ),
    PieceTheme(
      name: 'Teal vs Coral',
      player1Color: const Color(0xFF008080),
      player2Color: const Color(0xFFFF7F50),
    ),
    PieceTheme(
      name: 'Navy vs Crimson',
      player1Color: const Color(0xFF000080),
      player2Color: const Color(0xFFDC143C),
    ),
    PieceTheme(
      name: 'Forest vs Fire',
      player1Color: const Color(0xFF228B22),
      player2Color: const Color(0xFFFF4500),
    ),
    PieceTheme(
      name: 'Slate vs Rose',
      player1Color: const Color(0xFF708090),
      player2Color: const Color(0xFFFF69B4),
    ),
    PieceTheme(
      name: 'Chocolate vs Cream',
      player1Color: const Color(0xFF3E2723),
      player2Color: const Color(0xFFFFF8DC),
    ),
  ];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    _lightSquareColor = Color(_prefs?.getInt('lightSquareColor') ?? defaultLightSquare.toARGB32());
    _darkSquareColor = Color(_prefs?.getInt('darkSquareColor') ?? defaultDarkSquare.toARGB32());
    _player1Color = Color(_prefs?.getInt('player1Color') ?? defaultPlayer1Color.toARGB32());
    _player2Color = Color(_prefs?.getInt('player2Color') ?? defaultPlayer2Color.toARGB32());
    notifyListeners();
  }

  Future<void> setLightSquareColor(Color color) async {
    _lightSquareColor = color;
    await _prefs?.setInt('lightSquareColor', color.toARGB32());
    notifyListeners();
  }

  Future<void> setDarkSquareColor(Color color) async {
    _darkSquareColor = color;
    await _prefs?.setInt('darkSquareColor', color.toARGB32());
    notifyListeners();
  }

  Future<void> setPlayer1Color(Color color) async {
    _player1Color = color;
    await _prefs?.setInt('player1Color', color.toARGB32());
    notifyListeners();
  }

  Future<void> setPlayer2Color(Color color) async {
    _player2Color = color;
    await _prefs?.setInt('player2Color', color.toARGB32());
    notifyListeners();
  }

  Future<void> setBoardTheme(BoardTheme theme) async {
    await setLightSquareColor(theme.lightColor);
    await setDarkSquareColor(theme.darkColor);
  }

  Future<void> setPieceTheme(PieceTheme theme) async {
    await setPlayer1Color(theme.player1Color);
    await setPlayer2Color(theme.player2Color);
  }

  Future<void> resetToDefaults() async {
    await setLightSquareColor(defaultLightSquare);
    await setDarkSquareColor(defaultDarkSquare);
    await setPlayer1Color(defaultPlayer1Color);
    await setPlayer2Color(defaultPlayer2Color);
  }
}

class BoardTheme {
  final String name;
  final Color lightColor;
  final Color darkColor;

  BoardTheme({
    required this.name,
    required this.lightColor,
    required this.darkColor,
  });
}

class PieceTheme {
  final String name;
  final Color player1Color;
  final Color player2Color;

  PieceTheme({
    required this.name,
    required this.player1Color,
    required this.player2Color,
  });
}
