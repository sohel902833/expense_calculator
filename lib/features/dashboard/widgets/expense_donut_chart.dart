import 'dart:math' as math;

import 'package:expense_calculator/constants/currency.dart';
import 'package:flutter/material.dart';

/// A minimal donut chart drawn with [CustomPainter] (stroked arcs form the
/// ring, no filled-sector math needed) since no charting package is a
/// project dependency and a handful of stroked arcs covers this need
/// without adding one.
class ExpenseDonutChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final List<Color> colors;
  final double size;

  const ExpenseDonutChart({
    super.key,
    required this.data,
    required this.colors,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (s, e) => s + e.value);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(data: data, colors: colors, total: total),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${Currency.TAKA}${total.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                "Total",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final List<Color> colors;
  final double total;

  _DonutPainter({required this.data, required this.colors, required this.total});

  static const double _strokeWidth = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );

    if (total <= 0) {
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = (data[i].value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.total != total;
}
