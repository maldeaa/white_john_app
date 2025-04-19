import 'package:flutter/material.dart';

class ShopItem {
  final String name;
  final int cost;
  final VoidCallback onPurchase;

  ShopItem(this.name, this.cost, this.onPurchase);
}