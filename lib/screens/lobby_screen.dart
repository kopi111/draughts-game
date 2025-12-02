import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'online_game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String? guestUsername;

  const LobbyScreen({super.key, this.guestUsername});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _playerName = 'Player';
  bool _isCreatingRoom = false;
  bool _isJoiningRoom = false;
  String? _waitingRoomId;
  StreamSubscription? _roomSubscription;
  bool _isLoadingProfile = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    if (widget.guestUsername != null) {
      // Guest user - use provided username
      setState(() {
        _playerName = widget.guestUsername!;
        _isGuest = true;
        _isLoadingProfile = false;
      });
    } else {
      // Registered user - fetch from profile
      final username = await _firebaseService.getUsername();
      if (mounted) {
        setState(() {
          _playerName = username ?? 'Player';
          _isGuest = false;
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    if (_waitingRoomId != null) {
      _firebaseService.leaveRoom(_waitingRoomId!);
    }
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _isCreatingRoom = true;
    });

    final roomId = await _firebaseService.createRoom(_playerName);

    if (roomId != null) {
      setState(() {
        _waitingRoomId = roomId;
      });

      // Listen for another player to join
      _roomSubscription = _firebaseService.listenToRoom(roomId).listen((room) {
        if (room != null && room.isPlaying && mounted) {
          _roomSubscription?.cancel();
          // Clear waitingRoomId so dispose() doesn't delete the room
          final gameRoomId = _waitingRoomId;
          _waitingRoomId = null;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OnlineGameScreen(
                roomId: gameRoomId!,
                isHost: true,
                playerName: _playerName,
              ),
            ),
          );
        }
      });
    } else {
      setState(() {
        _isCreatingRoom = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create room. Please try again.')),
        );
      }
    }
  }

  Future<void> _joinRoom(GameRoom room) async {
    setState(() {
      _isJoiningRoom = true;
    });

    final success = await _firebaseService.joinRoom(room.id, _playerName);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnlineGameScreen(
            roomId: room.id,
            isHost: false,
            playerName: _playerName,
          ),
        ),
      );
    } else {
      setState(() {
        _isJoiningRoom = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join room. It may be full.')),
        );
      }
    }
  }

  void _cancelWaiting() {
    _roomSubscription?.cancel();
    if (_waitingRoomId != null) {
      _firebaseService.leaveRoom(_waitingRoomId!);
    }
    setState(() {
      _isCreatingRoom = false;
      _waitingRoomId = null;
    });
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
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFFE94560)],
                      ).createShader(bounds),
                      child: const Text(
                        'ONLINE PLAY',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Player info card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isGuest
                          ? Colors.orange.withValues(alpha: 0.5)
                          : const Color(0xFF00D9FF).withValues(alpha: 0.5),
                    ),
                  ),
                  child: _isLoadingProfile
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
                        )
                      : Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isGuest
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : const Color(0xFF00D9FF).withValues(alpha: 0.2),
                              ),
                              child: Icon(
                                _isGuest ? Icons.person_outline : Icons.verified_user,
                                color: _isGuest ? Colors.orange : const Color(0xFF00D9FF),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _playerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isGuest ? 'Playing as Guest' : 'Registered Player',
                                    style: TextStyle(
                                      color: _isGuest
                                          ? Colors.orange.withValues(alpha: 0.8)
                                          : const Color(0xFF00D9FF).withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isGuest)
                              IconButton(
                                onPressed: () async {
                                  await _firebaseService.signOut();
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                icon: const Icon(Icons.logout, color: Colors.white54),
                                tooltip: 'Sign Out',
                              ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Create room button or waiting state
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _waitingRoomId != null
                    ? _buildWaitingCard()
                    : ElevatedButton.icon(
                        onPressed: _isCreatingRoom || _isJoiningRoom ? null : _createRoom,
                        icon: _isCreatingRoom
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add),
                        label: Text(_isCreatingRoom ? 'Creating...' : 'Create Room'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Available rooms header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    const Icon(Icons.gamepad, color: Color(0xFF00D9FF), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Available Rooms',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Room list
              Expanded(
                child: StreamBuilder<List<GameRoom>>(
                  stream: _firebaseService.getAvailableRooms(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.withValues(alpha: 0.7),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading rooms',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final rooms = snapshot.data ?? [];

                    if (rooms.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              color: Colors.white.withValues(alpha: 0.3),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No rooms available',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a room to start playing!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return _buildRoomCard(room);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00D9FF)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF00D9FF),
          ),
          const SizedBox(height: 16),
          const Text(
            'Waiting for opponent...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Room ID: ${_waitingRoomId!.substring(0, 8)}...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _cancelWaiting,
            icon: const Icon(Icons.cancel, color: Color(0xFFE94560)),
            label: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFE94560)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(GameRoom room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00D9FF).withValues(alpha: 0.2),
          child: const Icon(Icons.person, color: Color(0xFF00D9FF)),
        ),
        title: Text(
          room.hostName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Waiting for opponent',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: _isJoiningRoom || _isCreatingRoom ? null : () => _joinRoom(room),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE94560),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isJoiningRoom
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Join'),
        ),
      ),
    );
  }
}
