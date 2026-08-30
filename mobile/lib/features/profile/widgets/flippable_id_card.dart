import 'dart:math';
import 'package:flutter/material.dart';

/// Tap-to-flip 3D card (perspective Y-rotation). Shows [front] for the
/// first half of the rotation and [back] for the second half, with the
/// back content counter-rotated so it isn't rendered mirrored.
class FlippableIdCard extends StatefulWidget {
  const FlippableIdCard({super.key, required this.front, required this.back});
  final Widget front;
  final Widget back;

  @override
  State<FlippableIdCard> createState() => _FlippableIdCardState();
}

class _FlippableIdCardState extends State<FlippableIdCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  bool _showingFront = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showingFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _showingFront = !_showingFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;
          final isShowingFront = angle <= pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isShowingFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

/// Decorative only — not a real scannable barcode standard (Code128 etc.),
/// just a visually-plausible bar pattern deterministically derived from
/// [seed] so the same id always renders the same bars.
class BarcodePainter extends CustomPainter {
  const BarcodePainter({required this.seed});
  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed.hashCode);
    final paint = Paint()..color = Colors.black;
    double x = 0;
    while (x < size.width) {
      final barWidth = 1.0 + random.nextInt(3);
      if (random.nextBool()) {
        canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
      }
      x += barWidth + 1;
    }
  }

  @override
  bool shouldRepaint(covariant BarcodePainter oldDelegate) => oldDelegate.seed != seed;
}
