# Draughts Game

A beautiful, fully-featured Draughts (Checkers) game built with Flutter. Play against an AI opponent with 5 difficulty levels or challenge a friend in 2-player mode.

## Features

- **Full-Screen Responsive Board** - The game board adapts to any screen size, from small phones to large tablets
- **5 AI Difficulty Levels**:
  - Beginner: Random moves - perfect for learning
  - Easy: Thinks 1 move ahead
  - Medium: Thinks 3 moves ahead
  - Hard: Thinks 5 moves ahead
  - Expert: Thinks 7 moves ahead - very challenging!
- **2-Player Mode** - Play against a friend on the same device
- **Smooth Animations** - Pieces animate when moving, capturing, and becoming kings
- **Visual Feedback** - Selected pieces glow, valid moves are highlighted
- **King Pieces** - Regular pieces become kings when reaching the opposite end
- **Mandatory Captures** - Enforces the rule that captures must be taken when available
- **Multi-Jump Chains** - Continue capturing if additional jumps are available

## Screenshots

The game features a clean, modern UI with:
- Deep navy/blue gradient background
- Gold and green checkerboard
- Overlay controls for back and reset
- Turn indicator at the bottom

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/draughts-game.git
cd draughts-game
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For Linux
flutter run -d linux

# For Android
flutter run -d android

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart                 # App entry point and theme configuration
├── models/
│   ├── piece.dart           # Piece model (color, king status)
│   ├── position.dart        # Board position model
│   └── game_state.dart      # Game state management
├── logic/
│   ├── game_logic.dart      # Core game rules and move validation
│   └── ai_player.dart       # AI opponent with minimax algorithm
├── screens/
│   ├── menu_screen.dart     # Main menu with game options
│   └── game_screen.dart     # Game board and UI
└── widgets/
    ├── board_widget.dart    # Checkerboard rendering
    └── piece_widget.dart    # Individual piece rendering
```

## Game Rules

1. **Movement**: Regular pieces move diagonally forward one square
2. **Capturing**: Jump over opponent pieces diagonally to capture them
3. **Mandatory Captures**: If a capture is available, you must take it
4. **Multi-Jumps**: If another capture is available after jumping, you must continue
5. **Kings**: Pieces reaching the opposite end become kings and can move backwards
6. **Winning**: Capture all opponent pieces or block all their moves

## AI Implementation

The AI uses the **Minimax algorithm with Alpha-Beta pruning** for efficient decision making:

- **Evaluation Function** considers:
  - Piece count and values (kings worth more)
  - Board position (center control bonus)
  - Piece advancement
  - Back row protection
  - King mobility

- **Search Depth** varies by difficulty:
  - Beginner: No search (random moves)
  - Easy: Depth 1
  - Medium: Depth 3
  - Hard: Depth 5
  - Expert: Depth 7

## Customization

### Changing Board Colors

Edit `lib/widgets/board_widget.dart`:
```dart
const lightColor = Color(0xFFFED100); // Gold squares
const darkColor = Color(0xFF009B3A);  // Green squares
```

### Changing Theme Colors

Edit `lib/main.dart`:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF0F3460), // Primary color
  brightness: Brightness.dark,
),
```

## Building for Release

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Linux
```bash
flutter build linux --release
```

### Web
```bash
flutter build web --release
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- AI powered by Minimax with Alpha-Beta pruning
