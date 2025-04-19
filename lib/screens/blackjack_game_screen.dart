import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:white_john_app/game_logic/blackjack_logic.dart';
import 'package:white_john_app/models/card_model.dart';
import 'package:white_john_app/screens/main_menu.dart';
import 'package:white_john_app/widgets/card_area.dart';
import 'package:white_john_app/widgets/combo_indicator.dart';
import 'package:white_john_app/widgets/game_button.dart';
import 'package:white_john_app/widgets/heart_indicator.dart';

class BlackjackGameScreen extends StatefulWidget {
  final User? user;

  const BlackjackGameScreen({super.key, this.user});

  @override
  State<BlackjackGameScreen> createState() => _BlackjackGameScreenState();
}

class _BlackjackGameScreenState extends State<BlackjackGameScreen>
    with TickerProviderStateMixin {
  late BlackjackLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = BlackjackLogic(this, user: widget.user);
    _initialize();
  }

  Future<void> _initialize() async {
    await _logic.initState();
    setState(() {});
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Выйти в меню?',
                style: TextStyle(color: Colors.white)),
            content: const Text(
              'Прогресс не сохранится. Вы уверены?',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    const Text('Отмена', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Выйти', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handleExit() async {
    if (await _showExitDialog()) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainMenu()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String dealerLabel =
        'Дилер: ${_logic.dealerCards.isEmpty || (_logic.isPlayerTurn && _logic.dealerFirstCardHidden) ? "?" : _logic.calculateScore(_logic.dealerCards)}';
    if (_logic.showDealerScorePrediction &&
        _logic.isPlayerTurn &&
        _logic.dealerFirstCardHidden &&
        _logic.dealerScorePrediction != null) {
      dealerLabel = 'Дилер: ? (предск.: ${_logic.dealerScorePrediction})';
    }
    if (_logic.showDealerFirstCard &&
        _logic.isPlayerTurn &&
        _logic.dealerFirstCardHidden &&
        _logic.dealerExtraCards != null) {
      dealerLabel += ' (+${_logic.dealerExtraCards} карт)';
    }

    String playerLabel =
        'Игрок: ${_logic.playerCards.isEmpty ? "?" : _logic.calculateScore(_logic.playerCards)}';
    if (_logic.showNextPlayerCard &&
        _logic.isPlayerTurn &&
        !_logic.isGameOver &&
        _logic.deck.isNotEmpty) {
      CardModel nextCard = _logic.deck.last;
      playerLabel += ' (след.: ${nextCard.display})';
    }

    return WillPopScope(
      onWillPop: _showExitDialog,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.grey),
              onPressed: _handleExit,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Очко',
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    HeartIndicator(hearts: _logic.hearts),
                    ComboIndicator(combo: _logic.combo),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CardArea(
                        cards: _logic.dealerCards,
                        label: dealerLabel,
                        showFirstCardOverlay: _logic.showDealerFirstCard &&
                            _logic.dealerFirstCardHidden,
                      ),
                      const SizedBox(height: 20),
                      CardArea(
                        cards: _logic.playerCards,
                        label: playerLabel,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (_logic.isGameOver)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          _logic.getResult(),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400]),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_logic.isPlayerTurn && !_logic.isGameOver) ...[
                          GameButton(
                            text: 'Ещё',
                            onPressed: () {
                              setState(() {
                                _logic.hit();
                              });
                            },
                          ),
                          const SizedBox(width: 16),
                          GameButton(
                            text: 'Хватит',
                            onPressed: () {
                              setState(() {
                                _logic.stand();
                              });
                            },
                          ),
                        ] else ...[
                          GameButton(
                            text: 'Новая партия',
                            onPressed: () {
                              setState(() {
                                _logic.startNewGame();
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
