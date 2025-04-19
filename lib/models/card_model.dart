import 'package:flutter/animation.dart';

class CardModel {
  final String suit;
  final String value;
  int points;
  AnimationController? animationController;

  CardModel(this.suit, this.value, this.points, {this.animationController});

  String get display => '$value$suit';
}