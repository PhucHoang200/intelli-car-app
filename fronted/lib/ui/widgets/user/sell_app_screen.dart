import 'package:flutter/material.dart';
import 'sell_bottom_navigation_bar.dart';

class SellAppScreen extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const SellAppScreen({super.key, required this.child, required this.currentIndex});

  @override
  State<SellAppScreen> createState() => _SellAppScreenState();
}

class _SellAppScreenState extends State<SellAppScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: SellBottomNavigationBar(currentIndex: widget.currentIndex),
    );
  }
}