import 'package:flutter/material.dart';
import 'buy_bottom_navigation_bar.dart';

class BuyAppScreen extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const BuyAppScreen({super.key, required this.child, required this.currentIndex});

  @override
  State<BuyAppScreen> createState() => _BuyAppScreenState();
}

class _BuyAppScreenState extends State<BuyAppScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BuyBottomNavigationBar(currentIndex: widget.currentIndex),
    );
  }
}