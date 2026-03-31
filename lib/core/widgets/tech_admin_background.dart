import 'package:flutter/material.dart';

class TechAdminBackground extends StatelessWidget {
  const TechAdminBackground({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF07162A), Color(0xFF0A1D35), Color(0xFF081728)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: _CircuitBackgroundPainter())),
          if (padding != null)
            Padding(padding: padding!, child: child)
          else
            child,
        ],
      ),
    );
  }
}

class _CircuitBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0x001E6DC2), Color(0x33226BBA), Color(0x001A5BA0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Offset.zero & size, glowPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF2F6FAE).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final dotPaint = Paint()
      ..color = const Color(0xFF4EA6FF).withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.22)
      ..lineTo(size.width * 0.3, size.height * 0.22)
      ..lineTo(size.width * 0.35, size.height * 0.18)
      ..lineTo(size.width * 0.45, size.height * 0.18)
      ..lineTo(size.width * 0.48, size.height * 0.15)
      ..lineTo(size.width * 0.62, size.height * 0.15);

    final path2 = Path()
      ..moveTo(size.width * 0.72, size.height * 0.78)
      ..lineTo(size.width * 0.92, size.height * 0.78)
      ..lineTo(size.width * 0.92, size.height * 0.63)
      ..lineTo(size.width * 0.98, size.height * 0.63);

    final path3 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.86)
      ..lineTo(size.width * 0.2, size.height * 0.86)
      ..lineTo(size.width * 0.24, size.height * 0.9)
      ..lineTo(size.width * 0.37, size.height * 0.9)
      ..lineTo(size.width * 0.4, size.height * 0.95);

    final path4 = Path()
      ..moveTo(size.width * 0.73, size.height * 0.18)
      ..lineTo(size.width * 0.88, size.height * 0.18)
      ..lineTo(size.width * 0.88, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.3);

    canvas.drawPath(path1, linePaint);
    canvas.drawPath(path2, linePaint);
    canvas.drawPath(path3, linePaint);
    canvas.drawPath(path4, linePaint);

    final dots = <Offset>[
      Offset(size.width * 0.35, size.height * 0.18),
      Offset(size.width * 0.48, size.height * 0.15),
      Offset(size.width * 0.24, size.height * 0.9),
      Offset(size.width * 0.92, size.height * 0.78),
      Offset(size.width * 0.88, size.height * 0.3),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, 5.5, dotPaint);
      canvas.drawCircle(
        dot,
        1.8,
        Paint()..color = const Color(0xFF8FD0FF).withOpacity(0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
