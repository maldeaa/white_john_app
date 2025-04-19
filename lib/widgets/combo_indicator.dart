import 'package:flutter/material.dart';

class ComboIndicator extends StatefulWidget {
  final int combo;

  const ComboIndicator({super.key, required this.combo});

  @override
  State<ComboIndicator> createState() => _ComboIndicatorState();
}

class _ComboIndicatorState extends State<ComboIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ComboIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.combo != widget.combo && widget.combo > 0) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Text(
            'Комбо: ${widget.combo}',
            style: TextStyle(
                fontSize: 16,
                color: widget.combo > 0 ? Colors.yellow : Colors.grey[400]),
          ),
        );
      },
    );
  }
}