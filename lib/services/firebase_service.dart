import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/position.dart';

class GameRoom {
  final String id;
  final String hostId;
  final String hostName;
  final String? guestId;
  final String? guestName;
  final String status; // 'waiting', 'playing', 'finished'
  final Map<String, dynamic>? gameState;
  final DateTime createdAt;
  final PieceColor? hostColor;
  final String? currentTurn;
  final String? winnerId;

  GameRoom({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.guestId,
    this.guestName,
    required this.status,
    this.gameState,
    required this.createdAt,
    this.hostColor,
    this.currentTurn,
    this.winnerId,
  });

  factory GameRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameRoom(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? 'Player 1',
      guestId: data['guestId'],
      guestName: data['guestName'],
      status: data['status'] ?? 'waiting',
      gameState: data['gameState'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hostColor: data['hostColor'] == 'black' ? PieceColor.black : PieceColor.red,
      currentTurn: data['currentTurn'],
      winnerId: data['winnerId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'guestId': guestId,
      'guestName': guestName,
      'status': status,
      'gameState': gameState,
      'createdAt': Timestamp.fromDate(createdAt),
      'hostColor': hostColor == PieceColor.black ? 'black' : 'red',
      'currentTurn': currentTurn,
      'winnerId': winnerId,
    };
  }

  bool get isWaiting => status == 'waiting';
  bool get isPlaying => status == 'playing';
  bool get isFinished => status == 'finished';
  bool get isFull => guestId != null;
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // User profile cache
  String? _cachedUsername;
  String? get cachedUsername => _cachedUsername;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<String?> registerWithEmail(String email, String password, String username) async {
    try {
      // Check if username is already taken
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        return 'Username is already taken';
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Store user profile in Firestore
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'username': username,
          'usernameLower': username.toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
          'gamesPlayed': 0,
          'gamesWon': 0,
        });
        _cachedUsername = username;
        return null; // Success
      }
      return 'Registration failed';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'Password is too weak';
        case 'email-already-in-use':
          return 'Email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return e.message ?? 'Registration failed';
      }
    } catch (e) {
      debugPrint('Error registering: $e');
      return 'Registration failed: $e';
    }
  }

  // Login with email and password
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Fetch username
        await fetchUserProfile();
        return null; // Success
      }
      return 'Login failed';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This account has been disabled';
        default:
          return e.message ?? 'Login failed';
      }
    } catch (e) {
      debugPrint('Error logging in: $e');
      return 'Login failed: $e';
    }
  }

  // Fetch user profile
  Future<void> fetchUserProfile() async {
    if (currentUserId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        final data = doc.data();
        _cachedUsername = data?['username'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  // Get username for current user
  Future<String?> getUsername() async {
    if (_cachedUsername != null) return _cachedUsername;
    await fetchUserProfile();
    return _cachedUsername;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _cachedUsername = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Sign in anonymously for quick play (kept for backward compatibility)
  Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  // Create a new game room
  Future<String?> createRoom(String playerName) async {
    try {
      if (currentUserId == null) {
        await signInAnonymously();
      }

      final roomRef = await _firestore.collection('game_rooms').add({
        'hostId': currentUserId,
        'hostName': playerName,
        'guestId': null,
        'guestName': null,
        'status': 'waiting',
        'gameState': null,
        'createdAt': FieldValue.serverTimestamp(),
        'hostColor': 'black', // Host plays black (goes first)
        'currentTurn': null,
        'winnerId': null,
      });

      return roomRef.id;
    } catch (e) {
      debugPrint('Error creating room: $e');
      return null;
    }
  }

  // Get available rooms
  Stream<List<GameRoom>> getAvailableRooms() {
    return _firestore
        .collection('game_rooms')
        .where('status', isEqualTo: 'waiting')
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs.map((doc) => GameRoom.fromFirestore(doc)).toList();
          // Sort by createdAt locally
          rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rooms;
        });
  }

  // Join a room
  Future<bool> joinRoom(String roomId, String playerName) async {
    try {
      if (currentUserId == null) {
        await signInAnonymously();
      }

      await _firestore.collection('game_rooms').doc(roomId).update({
        'guestId': currentUserId,
        'guestName': playerName,
        'status': 'playing',
        'currentTurn': 'host', // Host goes first (black)
      });

      return true;
    } catch (e) {
      debugPrint('Error joining room: $e');
      return false;
    }
  }

  // Listen to room changes
  Stream<GameRoom?> listenToRoom(String roomId) {
    return _firestore
        .collection('game_rooms')
        .doc(roomId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return GameRoom.fromFirestore(doc);
        });
  }

  // Update game state
  Future<void> updateGameState(String roomId, GameState gameState, String nextTurn) async {
    try {
      await _firestore.collection('game_rooms').doc(roomId).update({
        'gameState': _gameStateToMap(gameState),
        'currentTurn': nextTurn,
      });
    } catch (e) {
      debugPrint('Error updating game state: $e');
    }
  }

  // End game
  Future<void> endGame(String roomId, String? winnerId) async {
    try {
      await _firestore.collection('game_rooms').doc(roomId).update({
        'status': 'finished',
        'winnerId': winnerId,
      });
    } catch (e) {
      debugPrint('Error ending game: $e');
    }
  }

  // Leave room
  Future<void> leaveRoom(String roomId) async {
    try {
      final doc = await _firestore.collection('game_rooms').doc(roomId).get();
      if (!doc.exists) return;

      final room = GameRoom.fromFirestore(doc);

      if (room.hostId == currentUserId) {
        // Host leaving - delete the room
        await _firestore.collection('game_rooms').doc(roomId).delete();
      } else if (room.guestId == currentUserId) {
        // Guest leaving - reset room to waiting
        await _firestore.collection('game_rooms').doc(roomId).update({
          'guestId': null,
          'guestName': null,
          'status': 'waiting',
          'gameState': null,
          'currentTurn': null,
        });
      }
    } catch (e) {
      debugPrint('Error leaving room: $e');
    }
  }

  // Delete old rooms (cleanup)
  Future<void> cleanupOldRooms() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final oldRooms = await _firestore
          .collection('game_rooms')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      for (final doc in oldRooms.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error cleaning up old rooms: $e');
    }
  }

  // Helper to convert GameState to Map
  Map<String, dynamic> _gameStateToMap(GameState gameState) {
    final boardData = <String, dynamic>{};
    gameState.board.forEach((position, piece) {
      final key = '${position.row}_${position.col}';
      boardData[key] = {
        'id': piece.id,
        'color': piece.color == PieceColor.black ? 'black' : 'red',
        'isKing': piece.isKing,
      };
    });

    return {
      'board': boardData,
      'currentTurn': gameState.currentTurn == PieceColor.black ? 'black' : 'red',
    };
  }

  // Helper to convert Map to GameState
  static GameState? mapToGameState(Map<String, dynamic>? map) {
    if (map == null) return null;

    try {
      final boardData = map['board'] as Map<String, dynamic>;
      final board = <Position, Piece>{};

      boardData.forEach((key, value) {
        final parts = key.split('_');
        final row = int.parse(parts[0]);
        final col = int.parse(parts[1]);
        final pieceMap = value as Map<String, dynamic>;

        board[Position(row, col)] = Piece(
          id: pieceMap['id'] as String,
          color: pieceMap['color'] == 'black' ? PieceColor.black : PieceColor.red,
          type: (pieceMap['isKing'] as bool? ?? false) ? PieceType.king : PieceType.normal,
        );
      });

      return GameState(
        board: board,
        currentTurn: map['currentTurn'] == 'black' ? PieceColor.black : PieceColor.red,
      );
    } catch (e) {
      debugPrint('Error parsing game state: $e');
      return null;
    }
  }
}
