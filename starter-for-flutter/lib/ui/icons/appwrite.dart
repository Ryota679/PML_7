import 'package:flutter/material.dart';

class AppwriteIcon extends StatelessWidget {
  final double size; // Desired width, height scales accordingly
  final Color color;

  const AppwriteIcon({
    super.key,
    this.size = 40,
    this.color = const Color(0xFFFD366E),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * (105 / 112),
      child: CustomPaint(
        painter: _AppwriteIconPainter(color),
      ),
    );
  }
}

class _AppwriteIconPainter extends CustomPainter {
  final Color color;

  _AppwriteIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.992, size.height * 0.75)
      ..lineTo(size.width * 0.992, size.height)
      ..lineTo(size.width * 0.436, size.height)
      ..cubicTo(
        size.width * 0.274,
        size.height,
        size.width * 0.133,
        size.height * 0.9,
        size.width * 0.058,
        size.height * 0.75,
      )
      ..cubicTo(
        size.width * 0.047,
        size.height * 0.72,
        size.width * 0.037,
        size.height * 0.69,
        size.width * 0.029,
        size.height * 0.66,
      )
      ..cubicTo(
        size.width * 0.013,
        size.height * 0.62,
        size.width * 0.004,
        size.height * 0.58,
        0,
        size.height * 0.53,
      )
      ..lineTo(0, size.height * 0.47)
      ..cubicTo(
        0.001,
        size.height * 0.46,
        0.002,
        size.height * 0.44,
        0.003,
        size.height * 0.43,
      )
      ..cubicTo(
        0.006,
        size.height * 0.41,
        0.01,
        size.height * 0.39,
        0.014,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.067,
        size.height * 0.15,
        size.width * 0.236,
        0,
        size.width * 0.436,
        0,
      )
      ..cubicTo(
        size.width * 0.637,
        0,
        size.width * 0.805,
        size.height * 0.15,
        size.width * 0.857,
        size.height * 0.36,
      )
      ..lineTo(size.width * 0.62, size.height * 0.36)
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.3,
        size.width * 0.514,
        size.height * 0.25,
        size.width * 0.436,
        size.height * 0.25,
      )
      ..cubicTo(
        size.width * 0.357,
        size.height * 0.25,
        size.width * 0.29,
        size.height * 0.3,
        size.width * 0.251,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.241,
        size.height * 0.38,
        size.width * 0.232,
        size.height * 0.41,
        size.width * 0.227,
        size.height * 0.43,
      )
      ..cubicTo(
        size.width * 0.221,
        size.height * 0.45,
        size.width * 0.218,
        size.height * 0.47,
        size.width * 0.218,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.218,
        size.height * 0.57,
        size.width * 0.244,
        size.height * 0.63,
        size.width * 0.277,
        size.height * 0.66,
      )
      ..cubicTo(
        size.width * 0.316,
        size.height * 0.71,
        size.width * 0.374,
        size.height * 0.75,
        size.width * 0.436,
        size.height * 0.75,
      )
      ..lineTo(size.width * 0.992, size.height * 0.75)
      ..close();

    final path2 = Path()
      ..moveTo(size.width * 0.992, size.height * 0.43)
      ..lineTo(size.width * 0.992, size.height * 0.66)
      ..lineTo(size.width * 0.586, size.height * 0.66)
      ..cubicTo(
        size.width * 0.63,
        size.height * 0.63,
        size.width * 0.654,
        size.height * 0.57,
        size.width * 0.654,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.654,
        size.height * 0.47,
        size.width * 0.651,
        size.height * 0.45,
        size.width * 0.646,
        size.height * 0.43,
      )
      ..lineTo(size.width * 0.992, size.height * 0.43)
      ..close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
