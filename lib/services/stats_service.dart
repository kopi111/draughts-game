import 'package:shared_preferences/shared_preferences.dart';
import '../logic/ai_player.dart';

class StatsService {
  static final StatsService _instance = StatsService._internal();
  factory StatsService() => _instance;
  StatsService._internal();

  SharedPreferences? _prefs;

  // Stats
  int _gamesPlayed = 0;
  int _gamesWon = 0;
  int _gamesLost = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalCaptures = 0;
  int _totalKings = 0;

  // Per difficulty stats
  final Map<Difficulty, int> _winsPerDifficulty = {};
  final Map<Difficulty, int> _gamesPerDifficulty = {};

  // Getters
  int get gamesPlayed => _gamesPlayed;
  int get gamesWon => _gamesWon;
  int get gamesLost => _gamesLost;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get totalCaptures => _totalCaptures;
  int get totalKings => _totalKings;
  double get winRate => _gamesPlayed > 0 ? (_gamesWon / _gamesPlayed) * 100 : 0;

  int winsForDifficulty(Difficulty d) => _winsPerDifficulty[d] ?? 0;
  int gamesForDifficulty(Difficulty d) => _gamesPerDifficulty[d] ?? 0;
  double winRateForDifficulty(Difficulty d) {
    final games = gamesForDifficulty(d);
    if (games == 0) return 0;
    return (winsForDifficulty(d) / games) * 100;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadStats();
  }

  void _loadStats() {
    _gamesPlayed = _prefs?.getInt('gamesPlayed') ?? 0;
    _gamesWon = _prefs?.getInt('gamesWon') ?? 0;
    _gamesLost = _prefs?.getInt('gamesLost') ?? 0;
    _currentStreak = _prefs?.getInt('currentStreak') ?? 0;
    _bestStreak = _prefs?.getInt('bestStreak') ?? 0;
    _totalCaptures = _prefs?.getInt('totalCaptures') ?? 0;
    _totalKings = _prefs?.getInt('totalKings') ?? 0;

    for (final d in Difficulty.values) {
      _winsPerDifficulty[d] = _prefs?.getInt('wins_${d.name}') ?? 0;
      _gamesPerDifficulty[d] = _prefs?.getInt('games_${d.name}') ?? 0;
    }
  }

  Future<void> _saveStats() async {
    await _prefs?.setInt('gamesPlayed', _gamesPlayed);
    await _prefs?.setInt('gamesWon', _gamesWon);
    await _prefs?.setInt('gamesLost', _gamesLost);
    await _prefs?.setInt('currentStreak', _currentStreak);
    await _prefs?.setInt('bestStreak', _bestStreak);
    await _prefs?.setInt('totalCaptures', _totalCaptures);
    await _prefs?.setInt('totalKings', _totalKings);

    for (final d in Difficulty.values) {
      await _prefs?.setInt('wins_${d.name}', _winsPerDifficulty[d] ?? 0);
      await _prefs?.setInt('games_${d.name}', _gamesPerDifficulty[d] ?? 0);
    }
  }

  Future<void> recordWin({Difficulty? difficulty}) async {
    _gamesPlayed++;
    _gamesWon++;
    _currentStreak++;
    if (_currentStreak > _bestStreak) {
      _bestStreak = _currentStreak;
    }

    if (difficulty != null) {
      _winsPerDifficulty[difficulty] = (_winsPerDifficulty[difficulty] ?? 0) + 1;
      _gamesPerDifficulty[difficulty] = (_gamesPerDifficulty[difficulty] ?? 0) + 1;
    }

    await _saveStats();
  }

  Future<void> recordLoss({Difficulty? difficulty}) async {
    _gamesPlayed++;
    _gamesLost++;
    _currentStreak = 0;

    if (difficulty != null) {
      _gamesPerDifficulty[difficulty] = (_gamesPerDifficulty[difficulty] ?? 0) + 1;
    }

    await _saveStats();
  }

  Future<void> recordCapture() async {
    _totalCaptures++;
    await _prefs?.setInt('totalCaptures', _totalCaptures);
  }

  Future<void> recordKing() async {
    _totalKings++;
    await _prefs?.setInt('totalKings', _totalKings);
  }

  Future<void> resetStats() async {
    _gamesPlayed = 0;
    _gamesWon = 0;
    _gamesLost = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _totalCaptures = 0;
    _totalKings = 0;
    _winsPerDifficulty.clear();
    _gamesPerDifficulty.clear();
    await _saveStats();
  }

  // Achievements check
  List<Achievement> getUnlockedAchievements() {
    final achievements = <Achievement>[];

    if (_gamesWon >= 1) {
      achievements.add(Achievement(
        id: 'first_win',
        title: 'First Victory',
        description: 'Win your first game',
        icon: '🏆',
      ));
    }

    if (_gamesWon >= 10) {
      achievements.add(Achievement(
        id: 'ten_wins',
        title: 'Getting Good',
        description: 'Win 10 games',
        icon: '⭐',
      ));
    }

    if (_gamesWon >= 50) {
      achievements.add(Achievement(
        id: 'fifty_wins',
        title: 'Draughts Master',
        description: 'Win 50 games',
        icon: '👑',
      ));
    }

    if (_bestStreak >= 5) {
      achievements.add(Achievement(
        id: 'streak_5',
        title: 'On Fire',
        description: '5 wins in a row',
        icon: '🔥',
      ));
    }

    if (_bestStreak >= 10) {
      achievements.add(Achievement(
        id: 'streak_10',
        title: 'Unstoppable',
        description: '10 wins in a row',
        icon: '💪',
      ));
    }

    if (winsForDifficulty(Difficulty.expert) >= 1) {
      achievements.add(Achievement(
        id: 'expert_win',
        title: 'Expert Slayer',
        description: 'Beat Expert difficulty',
        icon: '🎯',
      ));
    }

    if (_totalCaptures >= 100) {
      achievements.add(Achievement(
        id: 'captures_100',
        title: 'Piece Hunter',
        description: 'Capture 100 pieces',
        icon: '🎪',
      ));
    }

    if (_totalKings >= 20) {
      achievements.add(Achievement(
        id: 'kings_20',
        title: 'King Maker',
        description: 'Create 20 kings',
        icon: '♔',
      ));
    }

    return achievements;
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
