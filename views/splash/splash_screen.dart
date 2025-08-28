import 'dart:async';
import 'package:flutter/material.dart';
import 'package:launch/viewmodels/activity_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:launch/core/constant/colors.dart';
import 'package:launch/viewmodels/auth_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 설정
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // 애니메이션 시작
    _animationController.forward();

    // 인증 상태 확인 및 라우팅
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 인증 상태 확인
  Future<void> _checkAuthStatus() async {
    // 애니메이션을 위한 최소 표시 시간
    await Future.delayed(const Duration(milliseconds: 2500));

    // 컨텍스트가 유효한지 확인
    if (!mounted) return;

    // 인증 상태 확인
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isLoggedIn = await authViewModel.checkAuthStatus();

    // 라우팅
    if (!mounted) return;

    if (isLoggedIn) {
      // 사용자 ID 가져오기 (Firebase User 객체의 uid 사용)
      final userId = authViewModel.user?.uid ?? '';

      if (userId.isNotEmpty) {
        // ActivityViewModel 초기화 (필요한 경우)
        final activityViewModel =
            Provider.of<ActivityViewModel>(context, listen: false);

        // 프레임이 완성된 후 데이터 로딩
        WidgetsBinding.instance.addPostFrameCallback((_) {
          activityViewModel.loadUserActivities(userId);
        });
      }

      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 로고
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 3,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "10",
                          style: TextStyle(
                            fontFamily: 'jua',
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 앱 이름
              const Text(
                "LAUNCH MODE",
                style: TextStyle(
                  fontFamily: 'jua',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 10),

              // 앱 설명
              Text(
                "The 10-Second Action App",
                style: TextStyle(
                  fontFamily: 'jua',
                  fontSize: 16,
                  color: Colors.grey[400],
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 60),

              // 로딩 인디케이터
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
