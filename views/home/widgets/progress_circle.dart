import 'dart:math';
import 'package:flutter/material.dart';

class ProgressCircle extends StatelessWidget {
  final double progress;
  final double size;
  final double lineWidth;
  final Color color;
  final Color backgroundColor;
  final Widget? child;

  const ProgressCircle({
    super.key,
    required this.progress,
    required this.size,
    required this.lineWidth,
    required this.color,
    required this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 배경 원
          CustomPaint(
            size: Size(size, size),
            painter: CirclePainter(
              progress: 1.0,
              color: backgroundColor,
              lineWidth: lineWidth,
            ),
          ),

          // 진행 상태 원
          CustomPaint(
            size: Size(size, size),
            painter: CirclePainter(
              progress: progress,
              color: color,
              lineWidth: lineWidth,
            ),
          ),

          // 내부 위젯
          if (child != null)
            Center(
              child: child,
            ),
        ],
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double lineWidth;

  CirclePainter({
    required this.progress,
    required this.color,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - lineWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    // 원형 진행바 그리기
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // 12시 방향에서 시작
      2 * pi * progress, // 진행 각도
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.lineWidth != lineWidth;
  }
}
