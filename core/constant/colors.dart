import 'package:flutter/material.dart';

class AppColors {
  // 주요 색상 - 더 선명하고 진한 색상으로 변경
  static const Color primaryColor = Color(0xFF7E57C2); // 메인 진한 퍼플
  static const Color accentColor = Color(0xFF5B9CDE); // 더 진한 파스텔 블루

  // 테마 색상 (파스텔 배경) - 더 진한 배경 색상으로 조정
  static const Color lavenderBg = Color(0xFFE6D6FF); // 라벤더 배경 (더 진함)
  static const Color peachBg = Color(0xFFFFDFC2); // 복숭아 배경 (더 진함)
  static const Color mintBg = Color(0xFFD5FFDF); // 민트 배경 (더 진함)
  static const Color softYellowBg = Color(0xFFFFEFC2); // 연한 노랑 배경 (더 진함)

  // 감정 색상 (더 선명한 버전으로 변경)
  static const Color energeticColor = Color(0xFFFFBF57); // 활기찬 감정 (진한 노랑)
  static const Color pleasantColor = Color(0xFF7DC992); // 편안한 감정 (진한 초록)
  static const Color calmColor = Color(0xFF6AAFDE); // 차분한 감정 (진한 파랑)
  static const Color tenseColor = Color(0xFFFF8C7A); // 긴장된 감정 (진한 빨강)

  // 진행 색상
  static const Color progressColor = Color(0xFF9F75E8); // 진행률 색상 (더 진한 보라)

  // 배경 색상
  static const Color backgroundColor = Color(0xFFE6D6FF); // 앱 배경 (더 진한 라벤더)
  static const Color surfaceColor = Color(0xFFF7F7F7); // 카드 배경 (약간 회색빛 화이트)
  static const Color cardHighlightColor =
      Color(0xFFDEDEDE); // 활동 카드 아이콘 배경 (더 진한 회색)

  // 텍스트 색상 - 가독성 향상을 위해 더 진한 색상으로 변경
  static const Color primaryTextColor = Color(0xFF262626); // 주요 텍스트 (매우 진한 회색)
  static const Color secondaryTextColor = Color(0xFF555555); // 보조 텍스트 (진한 회색)
  static const Color hintTextColor = Color(0xFF888888); // 힌트 텍스트 (중간 회색)

  // 기능 색상 - 더 눈에 띄게 조정
  static const Color successColor = Color(0xFF6DB888); // 성공 (진한 초록)
  static const Color warningColor = Color(0xFFFFB74D); // 경고 (진한 노랑)
  static const Color errorColor = Color(0xFFFF7D6B); // 오류 (진한 빨강)

  // 그라데이션 - 더 선명하게 조정
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7E57C2), Color(0xFF9C6FE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient focusGradient = LinearGradient(
    colors: [Color(0xFF5B9CDE), Color(0xFF7AADDD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 테마별 그라데이션 - 더 선명하고 식별이 쉽게 조정
  static const LinearGradient lavenderGradient = LinearGradient(
    colors: [Color(0xFFE6D6FF), Color(0xFFD6C2F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient peachGradient = LinearGradient(
    colors: [Color(0xFFFFDFC2), Color(0xFFFFD1A8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
