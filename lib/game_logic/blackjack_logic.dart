import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:white_john_app/models/card_model.dart';
import 'package:white_john_app/models/shop_item.dart';
import 'package:white_john_app/screens/blackjack_game_screen.dart';
import 'package:white_john_app/screens/lose_screen.dart';
import 'package:white_john_app/screens/win_screen.dart';

class BlackjackLogic {
  final State<BlackjackGameScreen> state;
  final User? user;

  List<CardModel> playerCards = [];
  List<CardModel> dealerCards = [];
  List<CardModel>? dealerFutureCards;
  bool isGameOver = false;
  bool isPlayerTurn = true;
  bool dealerFirstCardHidden = true;
  double hearts = 3.0;
  int combo = 0;
  int maxCombo = 0;
  int comboCoins = 0;
  List<ShopItem> shopItems = [];
  double blackjackChanceBoost = 0.0;
  int comboProtectionCount = 3;
  int maxShopItems = 3;
  bool hasSpentComboCoins = false;
  bool showDealerFirstCard = false;
  bool showDealerScorePrediction = false;
  bool showNextPlayerCard = false;
  int maxScore = 21;
  int? dealerExtraCards;
  int? dealerScorePrediction;
  int dealerFirstCardPurchases = 0;
  int dealerScorePredictionPurchases = 0;
  int nextPlayerCardPurchases = 0;
  int comboProtectionPurchases = 0;
  double dealerExtraCardsAccuracy = 0.95;
  bool isInfiniteMode = false;
  String? currentUsername;
  final List<String> suits = ['♠', '♥', '♣', '♦'];
  final List<String> values = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'J',
    'Q',
    'K',
    'A'
  ];
  List<CardModel> deck = [];

  BlackjackLogic(this.state, {this.user}) {
    playerCards = [];
    dealerCards = [];
  }

  Future<String> _getValidUsername() async {
    if (user == null) return 'Player';
    if (user!.isAnonymous) {
      final snapshot =
          await FirebaseFirestore.instance.collection('leaderboard').get();
      return 'Player_${snapshot.docs.length + 1}';
    }
    return user!.displayName ?? 'Player';
  }

  void _clearCards(List<CardModel> cards) {
    for (var card in cards) {
      card.animationController?.dispose();
      card.animationController = null;
    }
    cards.clear();
  }

  CardModel _createCard(
      {bool hidden = false, String? suit, String? value, int? points}) {
    if (deck.isEmpty) initializeDeck();
    final card = (suit == null || value == null || points == null)
        ? deck.removeLast()
        : CardModel(suit, value, points);
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: state as TickerProvider,
    );
    final newCard = CardModel(
      card.suit,
      card.value,
      hidden ? 0 : card.points,
      animationController: animationController,
    );
    animationController.forward();
    return newCard;
  }

  void _resetGameState() {
    hearts = 3.0;
    combo = 0;
    maxCombo = 0;
    comboCoins = 0;
    blackjackChanceBoost = 0.0;
    comboProtectionCount = 3;
    hasSpentComboCoins = false;
    showDealerFirstCard = false;
    showDealerScorePrediction = false;
    showNextPlayerCard = false;
    dealerExtraCards = null;
    dealerScorePrediction = null;
    dealerFutureCards = null;
    dealerFirstCardPurchases = 0;
    dealerScorePredictionPurchases = 0;
    nextPlayerCardPurchases = 0;
    comboProtectionPurchases = 0;
    maxScore = 21;
    maxShopItems = 3;
    isInfiniteMode = false;
    shopItems.clear();
    initializeShop();
  }

  int _getDealerTarget() {
    if (combo < 9 && !hasSpentComboCoins) {
      return Random().nextInt(3) + 9;
    } else if (combo < 15) {
      return Random().nextInt(3) + 14;
    }
    return 17;
  }

  Future<void> _saveToLeaderboard() async {
    if (user == null || maxCombo < 16 || currentUsername == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('leaderboard')
          .doc(user!.uid)
          .set({
        'username': currentUsername,
        'score': maxCombo,
        'timestamp': FieldValue.serverTimestamp(),
        'authProvider': user!.isAnonymous ? 'anonymous' : 'google',
        'isAnonymous': user!.isAnonymous,
      });
      debugPrint('Score saved to leaderboard: $maxCombo for ${user!.uid}');
    } catch (e) {
      debugPrint('Error saving score: $e');
    }
  }

  Future<void> initState() async {
    currentUsername = await _getValidUsername();
    initializeDeck();
    initializeShop();
    startNewGame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted) {
        ScaffoldMessenger.of(state.context).showSnackBar(
          const SnackBar(
            content: Text('Вы начинаете с 3 защитами от потери комбо!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void dispose() {
    _clearCards(playerCards);
    _clearCards(dealerCards);
    if (dealerFutureCards != null) _clearCards(dealerFutureCards!);
  }

  void initializeDeck() {
    deck.clear();
    for (var suit in suits) {
      for (var value in values) {
        final points = value == 'A'
            ? 11
            : ['J', 'Q', 'K'].contains(value)
                ? 10
                : int.parse(value);
        deck.add(CardModel(suit, value, points));
      }
    }
    deck.shuffle(Random());
  }

  List<ShopItem> _getShopItems() {
    return [
      ShopItem('+1 жизнь', 1, () => hearts = (hearts + 1).clamp(0.0, 4.0)),
      ShopItem(
          'Хил +0.5 жизни', 1, () => hearts = (hearts + 0.5).clamp(0.0, 3.0)),
      ShopItem('Хил +1 жизнь', 2, () => hearts = (hearts + 1).clamp(0.0, 3.0)),
      ShopItem('Защита комбо (1)', 2, () {
        if (comboProtectionCount < 3) {
          comboProtectionCount++;
          comboProtectionPurchases++;
        }
      }),
      ShopItem('+1 предмет в магазин', 3, () {
        if (maxShopItems < 5) {
          maxShopItems++;
          addRandomShopItem();
        }
      }),
      ShopItem(
          '+15% шанс блэкджека',
          5,
          () => blackjackChanceBoost =
              (blackjackChanceBoost + 0.15).clamp(0.0, 0.6)),
      if (dealerFirstCardPurchases == 0)
        ShopItem(
            'Видеть первую карту дилера и с 95% шансом количество остальных', 5,
            () {
          showDealerFirstCard = true;
          dealerFirstCardPurchases++;
        }),
      if (dealerScorePredictionPurchases == 0)
        ShopItem('Предсказание очков дилера (50% шанс)', 5, () {
          showDealerScorePrediction = true;
          dealerScorePredictionPurchases++;
        }),
      if (nextPlayerCardPurchases == 0)
        ShopItem('Видеть следующую карту', 5, () {
          showNextPlayerCard = true;
          nextPlayerCardPurchases++;
        }),
      ShopItem('+3 к максимальному очку', 5, () => maxScore += 3),
    ];
  }

  void initializeShop() {
    final allItems = _getShopItems();
    shopItems = (allItems..shuffle(Random())).take(maxShopItems).toList();
  }

  void addRandomShopItem() {
    final allItems = _getShopItems();
    if (allItems.isNotEmpty) {
      shopItems.add(allItems[Random().nextInt(allItems.length)]);
    }
  }

  void startNewGame() {
    _clearCards(playerCards);
    _clearCards(dealerCards);
    if (dealerFutureCards != null) _clearCards(dealerFutureCards!);
    isGameOver = false;
    isPlayerTurn = true;
    dealerFirstCardHidden = true;
    dealerExtraCards = null;
    dealerScorePrediction = null;
    dealerFutureCards = null;
    if (deck.length < 10) initializeDeck();
    dealInitialCards();
    if (showDealerFirstCard) simulateDealerPlay();
    if (showDealerScorePrediction) {
      int baseScore = dealerCards[1].points + Random().nextInt(11) + 1;
      dealerScorePrediction = Random().nextDouble() < 0.45
          ? (baseScore + Random().nextInt(5) - 2).clamp(0, maxScore)
          : baseScore.clamp(0, maxScore);
    }
    checkInitialBlackjack();
  }

  void simulateDealerPlay() {
    List<CardModel> tempDeck = List.from(deck);
    List<CardModel> tempDealerCards = List.from(dealerCards);
    dealerFutureCards = [];
    final dealerTarget = _getDealerTarget();

    tempDealerCards[0] = tempDeck.removeLast();
    dealerFutureCards!.add(tempDealerCards[0]);

    if (combo < 9 && !hasSpentComboCoins) {
      while (calculateScore(tempDealerCards) > 15) {
        tempDealerCards.removeLast();
        tempDealerCards[0] = tempDeck.removeLast();
        dealerFutureCards = [tempDealerCards[0]];
      }
      int extraCards = 0;
      while (calculateScore(tempDealerCards) < dealerTarget &&
          calculateScore(tempDealerCards) <= 15) {
        CardModel newCard = tempDeck.removeLast();
        tempDealerCards.add(newCard);
        dealerFutureCards!.add(newCard);
        extraCards++;
        if (calculateScore(tempDealerCards) > 15) {
          tempDealerCards.removeLast();
          dealerFutureCards!.removeLast();
          extraCards--;
          break;
        }
      }
      dealerExtraCards = Random().nextDouble() > dealerExtraCardsAccuracy
          ? (extraCards + Random().nextInt(3) - 1).clamp(0, extraCards + 1)
          : extraCards;
    } else {
      int extraCards = 0;
      while (calculateScore(tempDealerCards) < dealerTarget &&
          calculateScore(tempDealerCards) <= maxScore) {
        CardModel newCard = tempDeck.removeLast();
        tempDealerCards.add(newCard);
        dealerFutureCards!.add(newCard);
        extraCards++;
      }
      dealerExtraCards = Random().nextDouble() > dealerExtraCardsAccuracy
          ? (extraCards + Random().nextInt(3) - 1).clamp(0, extraCards + 1)
          : extraCards;
    }
  }

  void dealInitialCards() {
    do {
      _clearCards(playerCards);
      playerCards.add(_createCard());
      playerCards.add(_createCard());
    } while (calculateScore(playerCards) < 8);
    dealerCards.add(_createCard(hidden: true));
    dealerCards.add(_createCard());
    if (Random().nextDouble() < blackjackChanceBoost &&
        calculateScore(playerCards) != 21) {
      _clearCards(playerCards);
      playerCards.add(_createCard(suit: '♠', value: 'A', points: 11));
      playerCards.add(_createCard(suit: '♠', value: 'K', points: 10));
    }
  }

  int calculateScore(List<CardModel> cards, {bool ignoreHidden = false}) {
    List<CardModel> visibleCards =
        ignoreHidden ? cards.where((card) => card.points > 0).toList() : cards;
    int score = visibleCards.fold(0, (total, card) => total + card.points);
    int aces = visibleCards.where((card) => card.value == 'A').length;
    while (score > maxScore && aces > 0) {
      score -= 10;
      aces--;
    }
    return score;
  }

  void checkInitialBlackjack() {
    final playerScore = calculateScore(playerCards);
    if (playerScore == 21) {
      dealerFirstCardHidden = false;
      dealerCards[0] = _createCard();
      final dealerScore = calculateScore(dealerCards);
      isGameOver = true;
      isPlayerTurn = false;
      updateHeartsAndCombo(dealerScore, playerScore);
    }
  }

  void hit() {
    playerCards.add(_createCard());
    if (calculateScore(playerCards) > maxScore) {
      isGameOver = true;
      isPlayerTurn = false;
      dealerFirstCardHidden = false;
      updateHeartsAndCombo(
          calculateScore(dealerCards), calculateScore(playerCards));
    }
  }

  void stand() {
    isPlayerTurn = false;
    dealerFirstCardHidden = false;
    dealerPlay();
  }

  void dealerPlay() {
    CardModel firstCard = dealerCards[0];
    final dealerTarget = _getDealerTarget();

    if (showDealerFirstCard &&
        dealerFutureCards != null &&
        dealerFutureCards!.isNotEmpty) {
      dealerCards[0] = dealerFutureCards![0];
      dealerCards[0].animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: state as TickerProvider,
      );
      dealerCards[0].animationController?.forward();
      for (int i = 1; i < dealerFutureCards!.length; i++) {
        dealerCards.add(dealerFutureCards![i]);
        dealerCards[i].animationController = AnimationController(
          duration: const Duration(milliseconds: 800),
          vsync: state as TickerProvider,
        );
        dealerCards[i].animationController?.forward();
      }
    } else {
      dealerCards[0] = _createCard();
      if (combo < 9 && !hasSpentComboCoins) {
        while (calculateScore(dealerCards) > 15) {
          dealerCards.removeLast();
          dealerCards[0].animationController?.dispose();
          dealerCards[0] = _createCard();
        }
        while (calculateScore(dealerCards) < dealerTarget &&
            calculateScore(dealerCards) <= 15) {
          final newCard = _createCard();
          dealerCards.add(newCard);
          if (calculateScore(dealerCards) > 15) {
            dealerCards.removeLast();
            newCard.animationController?.dispose();
            break;
          }
        }
      } else {
        while (calculateScore(dealerCards) < dealerTarget &&
            calculateScore(dealerCards) <= maxScore) {
          dealerCards.add(_createCard());
        }
      }
    }
    isGameOver = true;
    if (showDealerFirstCard) {
      dealerCards[0] = firstCard;
      dealerCards[0].points = firstCard.value == 'A'
          ? 11
          : ['J', 'Q', 'K'].contains(firstCard.value)
              ? 10
              : int.parse(firstCard.value);
    }
    updateHeartsAndCombo(
        calculateScore(dealerCards), calculateScore(playerCards));
  }

  void updateHeartsAndCombo(int dealerScore, int playerScore) {
    final result = getResult();
    if (result.contains('Дилер победил')) {
      hearts -= 0.5;
      if (comboProtectionCount > 0) {
        comboProtectionCount--;
        ScaffoldMessenger.of(state.context).showSnackBar(
          SnackBar(
            content:
                Text('Защита комбо сработала! Осталось: $comboProtectionCount'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        combo = 0;
      }
      if ((isInfiniteMode && combo == 0) || hearts <= 0) {
        if (isInfiniteMode && maxCombo >= 16) _saveToLeaderboard();
        showLoseScreen(state.context);
      }
    } else if (result.contains('Вы победили') || result.contains('Ничья')) {
      combo++;
      maxCombo = max(maxCombo, combo);
      if (combo % 3 == 0) {
        comboCoins += 3;
        shopItems.clear();
        initializeShop();
        showShopDialog(state.context);
      }
      if (combo >= 3 && combo % 3 == 0 && result.contains('Вы победили')) {
        hearts = (hearts + 1).clamp(0.0, 3.0);
      }
    }
    if (combo > 15 && !isInfiniteMode) {
      showWinScreen(state.context);
    }
  }

  void showShopDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Магазин', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Монеты комбо: $comboCoins',
                    style: const TextStyle(color: Colors.yellow)),
                const SizedBox(height: 10),
                ...shopItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(item.name,
                                style: const TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: comboCoins >= item.cost
                                ? () {
                                    comboCoins -= item.cost;
                                    hasSpentComboCoins = true;
                                    item.onPurchase();
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                            ),
                            child: Text('${item.cost} комбо'),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void showLoseScreen(BuildContext context) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => LoseScreen(
        onRestart: () {
          Navigator.of(context).pop();
          _resetGameState();
          startNewGame();
        },
        isInfiniteMode: isInfiniteMode,
        combo: maxCombo,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ));
  }

  void showWinScreen(BuildContext context) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => WinScreen(
        onRestart: () {
          Navigator.of(context).pop();
          _resetGameState();
          startNewGame();
        },
        isInfiniteMode: isInfiniteMode,
        onStartInfinite: () {
          Navigator.of(context).pop();
          isInfiniteMode = true;
          startNewGame();
        },
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ));
  }

  String getResult() {
    final playerScore = calculateScore(playerCards);
    final dealerScore = calculateScore(dealerCards);

    if (playerScore == 21 && playerCards.length == 2) {
      return dealerScore == 21 && dealerCards.length == 2
          ? 'Ничья (двойной Blackjack)'
          : 'Blackjack! Вы победили!';
    }
    if (playerScore > maxScore) return 'Перебор! Дилер победил';
    if (dealerScore > maxScore) return 'Дилер перебрал! Вы победили';
    if (playerScore > dealerScore) return 'Вы победили!';
    if (dealerScore > playerScore) return 'Дилер победил';
    return 'Ничья';
  }
}
