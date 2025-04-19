// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:white_john_app/models/card_model.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;

  const CardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: card.animationController ?? AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        final value = (card.animationController?.value ?? 1.0).clamp(0.0, 1.0);
        final angle = value * pi;
        final isBack = angle < pi / 2;
        final opacity = value; 
        final offset = Offset((1 - value) * 80, 0); 

        return Transform.translate(
          offset: offset,
          child: Opacity(
            opacity: opacity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isBack)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) 
                      ..rotateY(angle),
                    child: Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/card_back_red.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                if (!isBack)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle - pi),
                    child: Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: card.points == 0
                            ? const Text('?',
                                style:
                                    TextStyle(fontSize: 28, color: Colors.grey))
                            : Text(
                                card.display,
                                style: TextStyle(
                                  fontSize: 28,
                                  color: card.suit == '♥' || card.suit == '♦'
                                      ? Colors.red[400]
                                      : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}