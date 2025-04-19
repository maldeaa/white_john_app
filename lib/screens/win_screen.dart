import 'package:flutter/material.dart';
import 'package:white_john_app/screens/main_menu.dart';
import 'package:white_john_app/widgets/game_button.dart';

class WinScreen extends StatelessWidget {
  final VoidCallback onRestart;
  final bool isInfiniteMode;
  final VoidCallback onStartInfinite;

  const WinScreen({
    super.key,
    required this.onRestart,
    this.isInfiniteMode = false,
    required this.onStartInfinite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: Text(
                isInfiniteMode
                    ? 'Отличная игра! Продолжайте в бесконечном режиме!'
                    : 'Победа! Комбо 15 достигнуто!',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            GameButton(
              text: isInfiniteMode ? 'Продолжить' : 'Начать бесконечный режим',
              onPressed: isInfiniteMode ? onRestart : onStartInfinite,
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
}