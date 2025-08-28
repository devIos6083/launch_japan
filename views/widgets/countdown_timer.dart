import 'package:flutter/material.dart';
import 'package:launch/core/constant/colors.dart';

class CountdownTimer extends StatelessWidget {
  final int seconds;
  final double progress;
  final double size;
  final Color backgroundColor;
  final Color progressColor;
  final Color textColor;
  final Widget? child;

  const CountdownTimer({
    super.key,
    required this.seconds,
    required this.progress,
    this.size = 200,
    this.backgroundColor = Colors.white, // 밝은 배경색으로 변경
    this.progressColor = AppColors.primaryColor,
    this.textColor = Colors.black87, // 검은색 텍스트로 변경
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 배경 원
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),

        // 진행 상태 원
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: const Color(0xFFE0E0E0), // 더 밝은 배경색
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),

        // 시간 표시
        if (child != null)
          child!
        else
          Text(
            seconds.toString(),
            style: TextStyle(
              fontFamily: 'jua',
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
      ],
    );
  }
}

class CountdownTimerWithBreath extends StatelessWidget {
  final int seconds;
  final double progress;
  final double size;
  final Color backgroundColor;
  final Color progressColor;
  final Color textColor;
  final Animation<double> breathAnimation;

  const CountdownTimerWithBreath({
    super.key,
    required this.seconds,
    required this.progress,
    required this.breathAnimation,
    this.size = 200,
    this.backgroundColor = Colors.white, // 밝은 배경색으로 변경
    this.progressColor = AppColors.primaryColor,
    this.textColor = Colors.black87, // 검은색 텍스트로 변경
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 배경 원
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),

        // 숨쉬는 원
        AnimatedBuilder(
          animation: breathAnimation,
          builder: (context, child) {
            return Container(
              width: size * (0.7 + breathAnimation.value * 0.1),
              height: size * (0.7 + breathAnimation.value * 0.1),
              decoration: BoxDecoration(
                color: progressColor
                    .withOpacity(0.1 + breathAnimation.value * 0.1),
                shape: BoxShape.circle,
              ),
            );
          },
        ),

        // 진행 상태 원
        SizedBox(
          width: size * 0.9,
          height: size * 0.9,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: const Color(0xFFE0E0E0), // 더 밝은 배경색
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),

        // 시간 표시
        Text(
          seconds.toString(),
          style: TextStyle(
            fontFamily: 'jua',
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
