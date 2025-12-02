import 'dart:async';
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/position.dart';
import '../models/game_state.dart';
import '../logic/game_logic.dart';
import '../services/firebase_service.dart';
import '../widgets/board_widget.dart';

class OnlineGameScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final String playerName;

  const OnlineGameScreen({
    super.key,
    required this.roomId,
    required this.isHost,
    required this.playerName,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late GameState _gameState;
  StreamSubscription? _roomSubscription;
  // ignore: unused_field
  GameRoom? _currentRoom;
  bool _isMyTurn = false;
  String _opponentName = 'Opponent';
  bool _opponentDisconnected = false;
  bool _hasConnected = false; // Track if we've received valid room data

  // Host plays black, guest plays red
  PieceColor get _myColor => widget.isHost ? PieceColor.black : PieceColor.red;
  PieceColor get _opponentColor => widget.isHost ? PieceColor.red : PieceColor.black;

  @override
  void initState() {
    super.initState();
    _gameState = GameState.initial();
    _isMyTurn = widget.isHost; // Host (black) goes first
    _startListeningToRoom();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  void _startListeningToRoom() {
    _roomSubscription = _firebaseService.listenToRoom(widget.roomId).listen((room) {
      if (room == null) {
        // Only show disconnect if we previously had a connection
        if (_hasConnected && mounted && !_opponentDisconnected) {
          setState(() {
            _opponentDisconnected = true;
          });
          _showOpponentLeftDialog();
        }
        return;
      }

      // Mark that we've connected successfully
      if (!_hasConnected) {
        _hasConnected = true;
      }

      setState(() {
        _currentRoom = room;
        _opponentName = widget.isHost
            ? (room.guestName ?? 'Opponent')
            : room.hostName;

        // Update game state from server
        if (room.gameState != null) {
          final serverState = FirebaseService.mapToGameState(room.gameState);
          if (serverState != null) {
            _gameState = serverState;
          }
        }

        // Determine whose turn it is
        _isMyTurn = (room.currentTurn == 'host' && widget.isHost) ||
            (room.currentTurn == 'guest' && !widget.isHost);

        // Check for game over
        if (room.isFinished && room.winnerId != null) {
          _showGameOverDialog(room.winnerId == _firebaseService.currentUserId);
        }
      });
    });
  }

  void _onSquareTap(Position position) {
    if (_gameState.status != GameStatus.playing) return;
    if (!_isMyTurn) return;

    final tappedPiece = _gameState.pieceAt(position);

    // If there's a must-continue situation
    if (_gameState.mustContinueFrom != null) {
      if (position == _gameState.mustContinueFrom) {
        final validMoves = GameLogic.getValidMoveDestinations(_gameState, position);
        setState(() {
          _gameState = _gameState.copyWith(
            selectedPosition: position,
            validMoves: validMoves,
          );
        });
      } else if (_gameState.validMoves.contains(position)) {
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
    if (tappedPiece != null && tappedPiece.color == _myColor) {
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

  void _makeMove(Position from, Position to) async {
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

    // Check for game over
    if (_gameState.status != GameStatus.playing) {
      final iWon = (_gameState.status == GameStatus.blackWins && _myColor == PieceColor.black) ||
          (_gameState.status == GameStatus.redWins && _myColor == PieceColor.red);
      await _firebaseService.endGame(
        widget.roomId,
        iWon ? _firebaseService.currentUserId : null,
      );
      return;
    }

    // If still my turn (multi-jump), don't sync yet
    if (_gameState.mustContinueFrom != null) {
      return;
    }

    // Sync to Firebase - switch turns
    final nextTurn = widget.isHost ? 'guest' : 'host';
    await _firebaseService.updateGameState(widget.roomId, _gameState, nextTurn);
  }

  void _showGameOverDialog(bool iWon) {
    if (!mounted) return;

    final winner = iWon ? 'You' : _opponentName;
    final winnerColor = iWon
        ? (_myColor == PieceColor.black ? const Color(0xFF1A1A2E) : const Color(0xFFC41E3A))
        : (_opponentColor == PieceColor.black ? const Color(0xFF1A1A2E) : const Color(0xFFC41E3A));

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
              '$winner Won!',
              style: TextStyle(color: winnerColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          iWon ? 'Congratulations! You won the game!' : '$_opponentName has won the game.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Lobby'),
          ),
        ],
      ),
    );
  }

  void _showOpponentLeftDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Row(
          children: [
            Icon(Icons.person_off, color: Colors.orange, size: 32),
            SizedBox(width: 8),
            Text(
              'Opponent Left',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '$_opponentName has disconnected from the game.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Lobby'),
          ),
        ],
      ),
    );
  }

  void _leaveGame() async {
    await _firebaseService.leaveRoom(widget.roomId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final currentPlayerName = _isMyTurn ? 'You' : _opponentName;
    final playerColor = _gameState.currentTurn == PieceColor.black
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFC41E3A);

    String turnText;
    if (_gameState.mustContinueFrom != null && _isMyTurn) {
      turnText = 'You must continue jumping!';
    } else {
      turnText = _isMyTurn ? 'Your Turn' : "$_opponentName's Turn";
    }

    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final shortestSide = screenSize.shortestSide;

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

          // Back button (top left)
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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2D2D44),
                      title: const Text(
                        'Leave Game?',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to leave this game?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _leaveGame();
                          },
                          child: const Text('Leave', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Player info (top right)
          Positioned(
            top: padding.top + 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: shortestSide * 0.03,
                vertical: shortestSide * 0.015,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(buttonSize * 0.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // My color indicator
                  Container(
                    width: indicatorSize,
                    height: indicatorSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _myColor == PieceColor.black
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFC41E3A),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                  SizedBox(width: shortestSide * 0.015),
                  Text(
                    widget.playerName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize * 0.9,
                    ),
                  ),
                  SizedBox(width: shortestSide * 0.03),
                  Text(
                    'vs',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: fontSize * 0.8,
                    ),
                  ),
                  SizedBox(width: shortestSide * 0.03),
                  Container(
                    width: indicatorSize,
                    height: indicatorSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _opponentColor == PieceColor.black
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFC41E3A),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                  SizedBox(width: shortestSide * 0.015),
                  Text(
                    _opponentName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize * 0.9,
                    ),
                  ),
                ],
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
                  border: Border.all(
                    color: _isMyTurn ? const Color(0xFF00D9FF) : playerColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isMyTurn)
                      SizedBox(
                        width: indicatorSize,
                        height: indicatorSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: playerColor,
                        ),
                      )
                    else
                      Container(
                        width: indicatorSize,
                        height: indicatorSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00D9FF),
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
}
