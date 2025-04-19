import 'package:flutter/material.dart';
import 'package:white_john_app/screens/main_menu.dart';
import 'package:white_john_app/widgets/game_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoseScreen extends StatefulWidget {
  final VoidCallback onRestart;
  final bool isInfiniteMode;
  final int combo;

  const LoseScreen({
    super.key,
    required this.onRestart,
    this.isInfiniteMode = false,
    required this.combo,
  });

  @override
  _LoseScreenState createState() => _LoseScreenState();
}

class _LoseScreenState extends State<LoseScreen> {
  bool _isCheckingConnection = true;
  bool _isFirebaseConnected = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('Нет подключения к интернету');
      }

      await FirebaseFirestore.instance
          .collection('leaderboard')
          .limit(1)
          .get(const GetOptions(source: Source.server));

      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
          _isFirebaseConnected = true;
          _connectionError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
          _isFirebaseConnected = false;
          _connectionError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingConnection) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!_isFirebaseConnected) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ошибка подключения',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _connectionError != null &&
                        _connectionError!.contains('network')
                    ? 'Нет интернета, вали отсюда!'
                    : 'Ошибка сервера. Попробуйте позже.\n$_connectionError',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GameButton(
                text: 'Попробовать снова',
                onPressed: () {
                  setState(() {
                    _isCheckingConnection = true;
                    _isFirebaseConnected = false;
                    _connectionError = null;
                  });
                  _checkFirebaseConnection();
                },
              ),
              const SizedBox(height: 10),
              GameButton(
                text: 'В главное меню',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainMenu()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    final ScrollController _scrollController = ScrollController();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: FutureBuilder<int?>(
                future: _getBestScore(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Ошибка загрузки счёта: ${snapshot.error}',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }
                  final bestScore = snapshot.data;
                  return Text(
                    bestScore != null
                        ? 'Игра окончена! Ваш лучший счёт: $bestScore'
                        : 'Игра окончена! Ваш счёт: ${widget.combo}',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _shouldShowLeaderboard().then((value) =>
                    value ? _getLeaderboardAroundPlayer() : Future.value([])),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Ошибка загрузки лидеров: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    );
                  }
                  final leaderboard = snapshot.data ?? [];
                  if (leaderboard.isEmpty) {
                    return const Text(
                      'Лидерборд пока недоступен',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final playerIndex = leaderboard.indexWhere((e) =>
                        e['uid'] == FirebaseAuth.instance.currentUser?.uid);
                    if (playerIndex != -1) {
                      final itemHeight = 48.0;
                      final scrollOffset = (playerIndex * itemHeight) -
                          (_scrollController.position.viewportDimension / 2) +
                          (itemHeight / 2);
                      _scrollController.jumpTo(scrollOffset.clamp(
                          0.0, _scrollController.position.maxScrollExtent));
                    }
                  });
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: leaderboard.length,
                    itemBuilder: (context, index) {
                      final entry = leaderboard[index];
                      final isCurrentPlayer = entry['uid'] ==
                          FirebaseAuth.instance.currentUser?.uid;
                      return ListTile(
                        tileColor: isCurrentPlayer
                            ? Colors.yellow.withOpacity(0.2)
                            : null,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                '${entry['rank']}. ${entry['username']}',
                                style: TextStyle(
                                  color: isCurrentPlayer
                                      ? Colors.yellow
                                      : Colors.white,
                                  fontWeight: isCurrentPlayer
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Text(
                              'Счёт: ${entry['score']}',
                              style: TextStyle(
                                color: isCurrentPlayer
                                    ? Colors.yellow
                                    : Colors.white,
                                fontWeight: isCurrentPlayer
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            GameButton(text: 'Новая игра', onPressed: widget.onRestart),
            const SizedBox(height: 10),
            GameButton(
              text: 'В главное меню',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainMenu()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _shouldShowLeaderboard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (widget.combo >= 16) return true;
    final doc = await FirebaseFirestore.instance
        .collection('leaderboard')
        .doc(user.uid)
        .get();
    return doc.exists;
  }

  Future<int?> _getBestScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user logged in');
      return widget.combo >= 16 ? widget.combo : null;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('leaderboard')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final score = doc.data()?['score'];
        if (score is int) {
          return score;
        }
      }
      if (widget.combo >= 16) {
        final username = user.isAnonymous
            ? 'Player_${DateTime.now().millisecondsSinceEpoch}'
            : user.displayName ?? 'Player';
        await FirebaseFirestore.instance
            .collection('leaderboard')
            .doc(user.uid)
            .set({
          'username': username,
          'score': widget.combo,
          'timestamp': FieldValue.serverTimestamp(),
          'authProvider': user.isAnonymous ? 'anonymous' : 'google',
          'isAnonymous': user.isAnonymous,
        });
        return widget.combo;
      }
      return null;
    } catch (e) {
      debugPrint('Error in _getBestScore: $e');
      return widget.combo >= 16 ? widget.combo : null;
    }
  }

  Future<List<Map<String, dynamic>>> _getLeaderboardAroundPlayer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user logged in');
      return [];
    }

    try {
      debugPrint('Fetching leaderboard for UID: ${user.uid}');
      var playerDoc = await FirebaseFirestore.instance
          .collection('leaderboard')
          .doc(user.uid)
          .get();

      String? playerUsername;
      int? playerScore;
      if (!playerDoc.exists && widget.combo >= 16) {
        playerUsername = user.isAnonymous
            ? 'Player_${DateTime.now().millisecondsSinceEpoch}'
            : user.displayName ?? 'Player';
        playerScore = widget.combo;
        await FirebaseFirestore.instance
            .collection('leaderboard')
            .doc(user.uid)
            .set({
          'username': playerUsername,
          'score': playerScore,
          'timestamp': FieldValue.serverTimestamp(),
          'authProvider': user.isAnonymous ? 'anonymous' : 'google',
          'isAnonymous': user.isAnonymous,
        });
        debugPrint('Created new leaderboard entry for ${user.uid}');
        playerDoc = await FirebaseFirestore.instance
            .collection('leaderboard')
            .doc(user.uid)
            .get();
      }

      if (playerDoc.exists) {
        final playerData = playerDoc.data();
        debugPrint('Player data: $playerData');
        if (playerData == null ||
            playerData['score'] == null ||
            playerData['username'] == null) {
          debugPrint('Invalid player data: $playerData');
          if (widget.combo >= 16) {
            playerUsername = user.isAnonymous
                ? 'Player_${DateTime.now().millisecondsSinceEpoch}'
                : user.displayName ?? 'Player';
            playerScore = widget.combo;
            await FirebaseFirestore.instance
                .collection('leaderboard')
                .doc(user.uid)
                .set({
              'username': playerUsername,
              'score': playerScore,
              'timestamp': FieldValue.serverTimestamp(),
              'authProvider': user.isAnonymous ? 'anonymous' : 'google',
              'isAnonymous': user.isAnonymous,
            });
            debugPrint('Updated invalid leaderboard entry for ${user.uid}');
            playerDoc = await FirebaseFirestore.instance
                .collection('leaderboard')
                .doc(user.uid)
                .get();
          } else {
            return [];
          }
        } else {
          playerScore = playerData['score'] as int;
          playerUsername = playerData['username'] as String;
        }
      } else if (widget.combo < 16) {
        debugPrint('Player not in leaderboard and combo < 16');
        return [];
      }

      final allPlayersSnapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .get();

      debugPrint(
          'Total players in leaderboard: ${allPlayersSnapshot.docs.length}');
      final entries = <Map<String, dynamic>>[];
      int rank = 1;

      for (var doc in allPlayersSnapshot.docs) {
        final data = doc.data();
        if (data['username'] is String && data['score'] is int) {
          entries.add({
            'uid': doc.id,
            'username': data['username'] as String,
            'score': data['score'] as int,
            'rank': rank++,
          });
        }
      }

      debugPrint('Leaderboard entries: $entries');
      if (entries.isEmpty &&
          widget.combo >= 16 &&
          playerUsername != null &&
          playerScore != null) {
        return [
          {
            'uid': user.uid,
            'username': playerUsername,
            'score': playerScore,
            'rank': 1,
          }
        ];
      }

      final playerIndex = entries.indexWhere((e) => e['uid'] == user.uid);
      if (playerIndex == -1 &&
          widget.combo >= 16 &&
          playerUsername != null &&
          playerScore != null) {
        entries.add({
          'uid': user.uid,
          'username': playerUsername,
          'score': playerScore,
          'rank': entries.isEmpty ? 1 : entries.last['rank'] + 1,
        });
      }

      final startIndex = (playerIndex - 3).clamp(0, entries.length);
      final endIndex = (playerIndex + 4).clamp(0, entries.length);
      final slicedEntries = entries.sublist(startIndex, endIndex);

      debugPrint('Sliced leaderboard entries: $slicedEntries');
      return slicedEntries;
    } catch (e) {
      debugPrint('Error in _getLeaderboardAroundPlayer: $e');
      if (widget.combo >= 16 && user != null) {
        final username = user.isAnonymous
            ? 'Player_${DateTime.now().millisecondsSinceEpoch}'
            : user.displayName ?? 'Player';
        return [
          {
            'uid': user.uid,
            'username': username,
            'score': widget.combo,
            'rank': 1,
          }
        ];
      }
      return [];
    }
  }
}
