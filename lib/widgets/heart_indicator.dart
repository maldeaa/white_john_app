import 'package:flutter/material.dart';

class HeartIndicator extends StatefulWidget {
  final double hearts;

  const HeartIndicator({super.key, required this.hearts});

  @override
  State<HeartIndicator> createState() => _HeartIndicatorState();
}

class _HeartIndicatorState extends State<HeartIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _animation = Tween<double>(begin: widget.hearts, end: widget.hearts)
        .animate(_controller);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(HeartIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hearts != widget.hearts) {
      _animation = Tween<double>(begin: oldWidget.hearts, end: widget.hearts)
          .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0);
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
      animation: _controller,
      builder: (context, child) {
        int fullHearts = _animation.value.floor();
        double partialHeart = _animation.value - fullHearts;
        return Row(
          children: List.generate(5, (index) {
            if (index < fullHearts) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: const Icon(Icons.favorite, color: Colors.red, size: 24),
              );
            } else if (index == fullHearts && partialHeart > 0) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: CustomPaint(
                  size: const Size(24, 24),
                  painter: _PartialHeartPainter(partialHeart),
                ),
              );
            } else {
              return const Icon(Icons.favorite_border,
                  color: Colors.grey, size: 24);
            }
          }),
        );
      },
    );
  }
}

class _PartialHeartPainter extends CustomPainter {
  final double fillFraction;

  _PartialHeartPainter(this.fillFraction);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBorder = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintFill = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height * 0.9)
      ..cubicTo(size.width * 0.1, size.height * 0.7, -size.width * 0.1, 
          size.height * 0.3, size.width / 2, size.height * 0.1)
      ..cubicTo(size.width + size.width * 0.1, size.height * 0.3, 
          size.width - size.width * 0.1, size.height * 0.7, size.width / 2, size.height * 0.9)
      ..close();

    canvas.drawPath(path, paintBorder);

    final fillPath = Path.from(path);
    final bounds = path.getBounds();
    fillPath.addRect(Rect.fromLTWH(
        bounds.left, 
        bounds.top, 
        bounds.width * fillFraction, 
        bounds.height));

    canvas.drawPath(
      Path.combine(PathOperation.intersect, path, fillPath),
      paintFill,
    );
  }

  @override
  bool shouldRepaint(_PartialHeartPainter oldDelegate) => 
      oldDelegate.fillFraction != fillFraction;
}