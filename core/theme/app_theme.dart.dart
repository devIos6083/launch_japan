import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:launch/core/constant/colors.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      // 기본 색상 테마 - 더 선명한 라이트 테마로 변경
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor,
        onPrimary: Colors.black87,
        secondary: AppColors.accentColor,
        surface: AppColors.surfaceColor,
        onSurface: AppColors.primaryTextColor,
        error: AppColors.errorColor,
      ),

      // 배경색 - 더 진한 라벤더 색상으로 변경
      scaffoldBackgroundColor: AppColors.backgroundColor,

      // 앱바 테마 - 더 진한 텍스트 색상으로 가독성 향상
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primaryTextColor),
        titleTextStyle: TextStyle(
          fontFamily: 'jua',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTextColor,
        ),
      ),

      // 버튼 테마 - 더 진한 주요 색상 사용
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'jua',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 2, // 약간의 그림자로 입체감 추가
        ),
      ),

      // 텍스트 버튼 테마 - 더 진한 글씨 색상으로 가독성 향상
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'jua',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 입력 필드 테마 - 색상 대비를 높여 가독성 향상
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // 흰색 배경으로 변경하여 글자 가독성 향상
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.cardHighlightColor,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryColor,
            width: 2.0,
          ),
        ),
        hintStyle: TextStyle(
          color: AppColors.hintTextColor,
          fontSize: 14,
          fontFamily: 'jua',
        ),
        errorStyle: TextStyle(
          color: AppColors.errorColor,
          fontSize: 12,
          fontFamily: 'jua',
        ),
      ),

      // 텍스트 테마 - 더 진한 텍스트 색상으로 가독성 향상
      textTheme: TextTheme(
        displayLarge: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextColor,
          ),
        ),
        displayMedium: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextColor,
          ),
        ),
        displaySmall: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextColor,
          ),
        ),
        headlineMedium: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextColor,
          ),
        ),
        titleLarge: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextColor,
          ),
        ),
        bodyLarge: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 16,
            color: AppColors.primaryTextColor,
          ),
        ),
        bodyMedium: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 14,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ),

      // 카드 테마 - 가독성을 위해 그림자 강화
      cardTheme: CardTheme(
        color: AppColors.surfaceColor,
        elevation: 2, // 그림자 더 강화
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.black.withOpacity(0.1), // 그림자 색상 더 진하게
      ),

      // 다이얼로그 테마
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 5, // 그림자 더 강화
        shadowColor: Colors.black.withOpacity(0.15), // 그림자 색상 더 진하게
      ),

      // 바텀시트 테마
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        elevation: 5, // 그림자 더 강화
        shadowColor: Colors.black.withOpacity(0.15), // 그림자 색상 더 진하게
      ),

      // 아이콘 테마
      iconTheme: IconThemeData(
        color: AppColors.primaryTextColor,
        size: 22,
      ),

      // 스위치 테마 - 색상 대비 향상
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor.withOpacity(0.5); // 더 진한 색상
          }
          return AppColors.cardHighlightColor;
        }),
      ),

      // 체크박스 테마 - 색상 대비 향상
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor;
          }
          return AppColors.cardHighlightColor;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // 다크 테마 - 더 선명한 색상으로 가독성 향상
  static ThemeData get darkPastelTheme {
    return ThemeData(
      useMaterial3: true,
      // 다크 모드에서도 선명한 색상 사용하여 가독성 향상
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryColor,
        onPrimary: Colors.white,
        secondary: AppColors.accentColor,
        // 어두운 배경에 맞는 더 선명한 색상들
        surface: Color(0xFF302636), // 더 진한 어두운 보라색
        onSurface: Colors.white,
        error: AppColors.errorColor,
      ),

      // 배경색 - 더 진한 색상으로 변경
      scaffoldBackgroundColor: Color(0xFF221B2D), // 더 진한 어두운 보라색 배경

      // 앱바 테마 - 가독성 향상
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          fontFamily: 'jua',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),

      // 입력 필드 테마 (다크모드)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF3A3045), // 어두운 환경에서도 입력 필드 구분이 잘 되는 색상
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryColor,
            width: 2.0,
          ),
        ),
        hintStyle: TextStyle(
          color: Colors.white70, // 다크 모드에서 힌트 색상
          fontSize: 14,
          fontFamily: 'jua',
        ),
        errorStyle: TextStyle(
          color: AppColors.errorColor,
          fontSize: 12,
          fontFamily: 'jua',
        ),
      ),

      // 텍스트 테마 (다크모드) - 어두운 배경에서 더 잘 보이는 색상
      textTheme: TextTheme(
        displayLarge: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        displayMedium: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bodyLarge: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        bodyMedium: GoogleFonts.getFont(
          'jua',
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white70, // 보조 텍스트는 약간 투명도 추가
          ),
        ),
      ),
    );
  }
}
