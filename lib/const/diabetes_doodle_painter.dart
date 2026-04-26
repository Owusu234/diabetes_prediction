import 'dart:math' as math;
import 'package:flutter/material.dart';

class DiabetesDoodlePainter extends CustomPainter {
  final Color iconColor;

  DiabetesDoodlePainter({required this.iconColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = iconColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final List<IconData> icons = [
      Icons.monitor_heart,
      Icons.water_drop,
      Icons.healing,
      Icons.fitness_center,
      Icons.apple,
      Icons.medical_services,
      Icons.science,
      Icons.speed,
      Icons.sports_gymnastics,
      Icons.bloodtype,
      Icons.bloodtype_outlined,
    ];

    final random = math.Random(42); // Fixed seed for consistent pattern
    const double spacing = 60.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Add some jitter to positions
        final double jitterX = random.nextDouble() * 20;
        final double jitterY = random.nextDouble() * 20;
        final double rotation = random.nextDouble() * math.pi / 4;
        
        final icon = icons[random.nextInt(icons.length)];
        
        _drawIcon(canvas, icon, Offset(x + jitterX, y + jitterY), rotation, paint);
      }
    }
  }

  void _drawIcon(Canvas canvas, IconData icon, Offset offset, double rotation, Paint paint) {
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 24,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: iconColor.withOpacity(0.12),
      ),
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(rotation);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
