import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:white_john_app/screens/blackjack_game_screen.dart';
import 'package:white_john_app/widgets/game_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  bool _isCheckingConnection = true;
  bool _isFirebaseConnected = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _initializeAuthAndConnection();
  }

  Future<void> _initializeAuthAndConnection() async {
    try {
      await _checkFirebaseConnection();
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
        _showAuthModalIfAnonymous();
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

  Future<bool> _testFirebaseConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      await FirebaseFirestore.instance
          .collection('leaderboard')
          .limit(1)
          .get(const GetOptions(source: Source.server));
      return true;
    } catch (e) {
      debugPrint('Firebase connection test failed: $e');
      return false;
    }
  }

  Future<void> _showAuthModalIfAnonymous() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Current user: ${user?.uid}, isAnonymous: ${user?.isAnonymous}');
    if (user == null || user.isAnonymous) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey[900],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            enableDrag: false,
            isDismissible: false,
            builder: (context) => WillPopScope(
              onWillPop: () async => false,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Йоу, чувак!',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Войди в свой Google аккаунт, чтобы твои рекорды сохранялись везде!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    GameButton(
                      text: 'Войти в Google',
                      onPressed: () async {
                        await _signInWithGoogle();
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        await _signInAnonymously();
                      },
                      child: const Text(
                        'или можешь остаться анонимом',
                        style: TextStyle(fontSize: 16, color: Colors.yellow),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      }
    }
  }

  Future<void> _signInAnonymously() async {
    if (!await _testFirebaseConnection()) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Нет интернета. Проверьте подключение.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      return;
    }
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      debugPrint('Anonymous sign-in successful: ${userCredential.user?.uid}');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Вход выполнен анонимно',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Ошибка анонимного входа: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!await _testFirebaseConnection()) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Нет интернета. Проверьте подключение.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      return;
    }
    try {
      debugPrint('Starting Google sign-in');
      final googleSignIn = GoogleSignIn();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint('Linking anonymous account with Google');
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          debugPrint('Google sign-in cancelled by user');
          Fluttertoast.showToast(
            msg: 'Вход через Google отменён',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.yellow[700],
            textColor: Colors.black,
            fontSize: 16.0,
          );
          return;
        }

        debugPrint('Google user selected: ${googleUser.email}');
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await currentUser.linkWithCredential(credential);
        debugPrint(
            'Linked Google account: ${userCredential.user?.uid}, email: ${userCredential.user?.email}');
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Google-аккаунт успешно связан',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          Navigator.pop(context);
        }
      } else {
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          debugPrint('Google sign-in cancelled by user');
          Fluttertoast.showToast(
            msg: 'Вход через Google отменён',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.yellow[700],
            textColor: Colors.black,
            fontSize: 16.0,
          );
          return;
        }

        debugPrint('Google user selected: ${googleUser.email}');
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        debugPrint(
            'Firebase sign-in successful: ${userCredential.user?.uid}, email: ${userCredential.user?.email}');
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Вход через Google успешен',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          Navigator.pop(context);
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      debugPrint('Google sign-in failed: $e\nStackTrace: $stackTrace');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Ошибка входа в Google: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
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
                  _initializeAuthAndConnection();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'White John - Блек-Джек наоборот',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'SF Pro',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SvgPicture.asset(
              'assets/svg/logo.svg',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 40),
            GameButton(
              text: 'Играть',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DeckSelectionScreen(
                            user: FirebaseAuth.instance.currentUser,
                          )),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DeckSelectionScreen extends StatelessWidget {
  final User? user;

  const DeckSelectionScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Выбор колоды',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/card_back_red.png',
                  width: 150,
                  height: 225,
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Колода Rapid',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Описание:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              const Text(
                'Классический блэкджек с уникальными механиками: собирайте комбо, чтобы открыть магазин с улучшениями, такими как предсказание очков дилера, просмотр своей следующей карты или увеличение максимального очка. Побеждайте дилера, зарабатывайте монеты и выживайте с помощью жизней!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Особенности:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              const Text(
                '- До 5 жизней (начало с 3)\n'
                '- 3 защиты комбо изначально\n'
                '- Ослабленный дилер до 9 комбо\n'
                '- Победа при 15+ комбо\n'
                '- Упрощённая экономика с комбо-монетами',
                style: TextStyle(fontSize: 16, color: Colors.yellow),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Center(
                child: GameButton(
                  text: 'Выбрать колоду',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              BlackjackGameScreen(user: user)),
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
}
