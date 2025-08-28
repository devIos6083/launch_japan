import 'package:flutter/material.dart';
import 'package:launch/viewmodels/auth_viewmodel.dart';
import 'package:launch/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:launch/core/constant/colors.dart';
import 'package:launch/viewmodels/countdown_viewmodel.dart';
import 'package:launch/viewmodels/activity_viewmodel.dart';
import 'package:launch/views/widgets/countdown_timer.dart';
import 'package:launch/views/widgets/app_button.dart';

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathAnimationController;
  late Animation<double> _breathAnimation;

  // 중복 호출 방지 플래그 추가
  bool _completedHandled = false;

  @override
  void initState() {
    super.initState();

    // 애니메이션 설정
    _breathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 카운트다운 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _breathAnimationController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    final countdownViewModel =
        Provider.of<CountdownViewModel>(context, listen: false);

    // 💥 중요: 카운트다운 시작 전에 상태를 리셋해주기
    countdownViewModel.resetCountdown();

    // 그 다음 카운트다운 시작
    countdownViewModel.startCountdown();
  }

  // 카운트다운 취소
  void _cancelCountdown() {
    final countdownViewModel =
        Provider.of<CountdownViewModel>(context, listen: false);
    countdownViewModel.cancelCountdown();
    Navigator.of(context).pop(false); // 취소된 경우 false 반환
  }

  // TTS 토글
  void _toggleTts() {
    final countdownViewModel =
        Provider.of<CountdownViewModel>(context, listen: false);
    countdownViewModel.toggleTts();
  }

  // _navigateToFocusTimer 메서드 수정
  void _navigateToFocusTimer() {
    final countdownViewModel =
        Provider.of<CountdownViewModel>(context, listen: false);

    // 💥 중요: 카운트다운이 정말 완료됐는지 한번 더 확인
    if (countdownViewModel.secondsRemaining <= 0) {
      // 통계 업데이트 코드를 다 지우고, 단순히 포커스 타이머 화면으로 이동만 하게 함
      Navigator.of(context).pushReplacementNamed('/focus_timer');
    } else {
      print('카운트다운이 아직 완료되지 않았습니다: ${countdownViewModel.secondsRemaining}초 남음');
    }
  }

  @override
  Widget build(BuildContext context) {
    final countdownViewModel = Provider.of<CountdownViewModel>(context);
    final activityViewModel = Provider.of<ActivityViewModel>(context);

    final selectedActivity = activityViewModel.selectedActivity;
    final seconds = countdownViewModel.secondsRemaining;
    final progress = countdownViewModel.progress;
    final isCompleted = countdownViewModel.isCompleted();
    final isTtsEnabled = countdownViewModel.isTtsEnabled;

    // 카운트다운 완료 체크 부분 수정 - 더 엄격하게!
    if (isCompleted && !_completedHandled && seconds <= 0) {
      _completedHandled = true; // 중복 호출 방지
      // 짧은 딜레이 추가해서 확실히 카운트다운이 끝난 후에 이동하도록
      Future.delayed(const Duration(milliseconds: 300), () {
        // 진짜 끝났는지 한번 더 확인
        if (countdownViewModel.secondsRemaining <= 0) {
          _navigateToFocusTimer();
        } else {
          // 아직 안 끝났으면 플래그 리셋
          setState(() {
            _completedHandled = false;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Row(
                  children: [
                    // 뒤로가기 버튼
                    GestureDetector(
                      onTap: _cancelCountdown,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 활동 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '카운트다운',
                          style: TextStyle(
                            fontFamily: 'jua',
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          selectedActivity?.name ?? '활동',
                          style: const TextStyle(
                            fontFamily: 'jua',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),

                    // 오른쪽 끝에 TTS 토글 버튼 추가
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleTts,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isTtsEnabled
                              ? AppColors.primaryColor
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Icon(
                            isTtsEnabled ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 카운트다운 타이머
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 큰 카운트다운 타이머
                      CountdownTimerWithBreath(
                        seconds: seconds,
                        progress: progress,
                        size: 280,
                        progressColor: AppColors.primaryColor,
                        breathAnimation: _breathAnimation,
                        backgroundColor: Colors.white, // 밝은 배경색
                        textColor: Colors.black87, // 어두운 텍스트 색상
                      ),
                      const SizedBox(height: 40),

                      // 안내 텍스트
                      Column(
                        children: [
                          const Text(
                            '카운트다운 후 바로 시작하세요',
                            style: TextStyle(
                              fontFamily: 'jua',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87, // 어두운 텍스트 색상
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '아무 생각없이, 바로 행동하세요!',
                            style: TextStyle(
                              fontFamily: 'jua',
                              fontSize: 14,
                              color: Colors.grey[700], // 어두운 텍스트 색상
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 버튼
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Center(
                  child: AppButton(
                    text: '취소',
                    onPressed: _cancelCountdown,
                    backgroundColor:
                        AppColors.primaryColor.withOpacity(0.1), // 연한 색상
                    textColor: AppColors.primaryColor, // 메인 색상
                    height: 45,
                    borderRadius: 22.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
