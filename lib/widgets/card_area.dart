import 'package:flutter/material.dart';
import 'package:white_john_app/models/card_model.dart';
import 'package:white_john_app/widgets/card_widget.dart';

class CardArea extends StatelessWidget {
  final List<CardModel> cards;
  final String label;
  final bool showFirstCardOverlay;

  const CardArea({
    super.key,
    required this.cards,
    required this.label,
    this.showFirstCardOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label,
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: cards.map((card) => CardWidget(card: card)).toList(),
              ),
              if (showFirstCardOverlay &&
                  cards.isNotEmpty &&
                  cards[0].points == 0)
                Positioned(
                  left: 0,
                  child: Opacity(
                    opacity: 0.5,
                    child: CardWidget(
                      card: CardModel(
                        cards[0].suit,
                        cards[0].value,
                        cards[0].value == 'A'
                            ? 11
                            : ['J', 'Q', 'K'].contains(cards[0].value)
                                ? 10
                                : int.parse(cards[0].value),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}