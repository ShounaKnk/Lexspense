import 'package:flutter/material.dart';

/// Renders a subtle, Nothing-inspired dot matrix background grid.
/// Engineered to provide atmospheric depth without overpowering text or UI elements.
class DotMatrixBackground extends StatelessWidget {
  final Widget child;
  final double spacing;
  final double dotRadius;

  const DotMatrixBackground({
    super.key,
    required this.child,
    this.spacing = 20.0,
    this.dotRadius = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dotColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: CustomPaint(
        painter: _DotMatrixPainter(
          dotColor: dotColor,
          spacing: spacing,
          dotRadius: dotRadius,
        ),
        child: child,
      ),
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double dotRadius;

  _DotMatrixPainter({
    required this.dotColor,
    required this.spacing,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Fast, lightweight grid drawing across canvas
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.dotRadius != dotRadius;
  }
}
