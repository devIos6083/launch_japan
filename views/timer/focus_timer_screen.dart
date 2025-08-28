import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:launch/core/constant/colors.dart';
import 'package:launch/viewmodels/timer_viewmodel.dart';
import 'package:launch/viewmodels/activity_viewmodel.dart';
import 'package:launch/viewmodels/profile_viewmodel.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 설정
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 컨텍스트 설정 및 타이머 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TimerViewModel에 Context 설정
      final timerViewModel =
          Provider.of<TimerViewModel>(context, listen: false);
      timerViewModel.setContext(context);

      _startTimer();
    });
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    super.dispose();
  }

  // 타이머 시작
  Future<void> _startTimer() async {
    final activityViewModel =
        Provider.of<ActivityViewModel>(context, listen: false);
    final timerViewModel = Provider.of<TimerViewModel>(context, listen: false);

    if (activityViewModel.selectedActivity != null) {
      await timerViewModel.startFocusTimer(activityViewModel.selectedActivity!);
    }
  }

  // 타이머 일시정지/재개
  void _togglePauseResume() {
    final timerViewModel = Provider.of<TimerViewModel>(context, listen: false);

    if (timerViewModel.isPaused) {
      timerViewModel.resumeTimer();
    } else {
      timerViewModel.pauseTimer();
    }
  }

  // 취소 버튼 (홈으로 돌아가기)
  void _goToHome() {
    _showExitConfirmDialog();
  }

  // 타이머 중지 (이제 취소 버튼 역할)
  void _stopTimer() {
    _showStopConfirmDialog();
  }

// FocusTimerScreen.dart - _completeTimer 메서드 수정
  Future<void> _completeTimer() async {
    final timerViewModel = Provider.of<TimerViewModel>(context, listen: false);

    // 타이머가 완료되지 않았으면 막기
    if (timerViewModel.remainingSeconds > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('타이머가 완료된 후에 체크할 수 있습니다.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final profileViewModel =
        Provider.of<ProfileViewModel>(context, listen: false);
    final activityViewModel =
        Provider.of<ActivityViewModel>(context, listen: false);

    // 타이머 완료 처리
    final success = await timerViewModel.completeTimer();

    if (success) {
      // 사용자 ID 가져오기
      final userId = activityViewModel.selectedActivity?.userId;

      if (userId != null) {
        try {
          // 중요: 여기서 오늘 요일을 명시적으로 가져와서 통계 업데이트
          final now = DateTime.now();
          final dayName = _getDayName(now.weekday); // 이 함수는 아래에 추가

          // 명시적으로 요일 통계 업데이트
          await profileViewModel
              .updateStatisticsAfterActivityCompletion(userId);

          // 홈으로 이동하기 전에 프로필 데이터 새로고침
          await profileViewModel.loadUserProfile(userId);

          // 활동 목록 새로고침
          await activityViewModel.loadUserActivities(userId);

          print('프로필 및 활동 데이터 새로고침 완료');
        } catch (e) {
          print('데이터 새로고침 중 오류: $e');
        }
      }

      // 완료 확인 스낵바 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('활동이 성공적으로 완료되었습니다!'),
            backgroundColor: AppColors.successColor,
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 홈 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('활동 완료 처리 중 오류가 발생했습니다.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

// 요일 이름을 얻는 헬퍼 메서드 추가
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  // 타이머 중지 확인 다이얼로그
  Future<void> _showStopConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          title: const Text(
            '타이머 중지',
            style: TextStyle(
              fontFamily: 'jua',
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '정말 타이머를 중지하시겠습니까?\n지금 중지하면 진행 상황이 저장되지 않습니다.',
            style: TextStyle(
              fontFamily: 'jua',
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'jua',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '중지',
                style: TextStyle(
                  fontFamily: 'jua',
                  color: AppColors.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final timerViewModel =
          Provider.of<TimerViewModel>(context, listen: false);
      await timerViewModel.stopTimer();

      if (mounted) {
        Navigator.of(context).pop(); // 현재 화면에서 뒤로 가기
      }
    }
  }

  // 홈으로 돌아가기 확인 다이얼로그
  Future<void> _showExitConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          title: const Text(
            '타이머 종료',
            style: TextStyle(
              fontFamily: 'jua',
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '타이머 화면을 나가시겠습니까?\n타이머가 중지되고 진행 상황이 저장되지 않습니다.',
            style: TextStyle(
              fontFamily: 'jua',
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontFamily: 'jua',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '나가기',
                style: TextStyle(
                  fontFamily: 'jua',
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final timerViewModel =
          Provider.of<TimerViewModel>(context, listen: false);
      await timerViewModel.stopTimer();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home'); // 홈 화면으로 이동
      }
    }
  }

  // 포맷된 시간 문자열 생성 (mm:ss)
  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timerViewModel = Provider.of<TimerViewModel>(context);
    final activityViewModel = Provider.of<ActivityViewModel>(context);

    final activity = activityViewModel.selectedActivity;
    final isRunning = timerViewModel.isRunning;
    final isPaused = timerViewModel.isPaused;
    final remainingSeconds = timerViewModel.remainingSeconds;
    final totalSeconds = timerViewModel.totalSeconds;
    final progress = timerViewModel.progress;

    // 타이머가 완료되었는지 확인 (체크 버튼 활성화 여부)
    final isTimerCompleted = remainingSeconds <= 0;

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
                padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 활동 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity?.name ?? '활동',
                          style: const TextStyle(
                            fontFamily: 'jua',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          activity?.description ?? '',
                          style: TextStyle(
                            fontFamily: 'jua',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 타이머 정보 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // 시간 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '남은 시간',
                          style: TextStyle(
                            fontFamily: 'jua',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(remainingSeconds),
                          style: const TextStyle(
                            fontFamily: 'jua',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // 진행 바
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 진행률 텍스트
                          Text(
                            '${(progress * 100).toInt()}% 완료',
                            style: TextStyle(
                              fontFamily: 'jua',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 진행 바
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  const Color(0xFFE0E0E0), // 더 밝은 배경색
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryColor),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 타이머 원
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _togglePauseResume,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isPaused ? 1.0 : _pulseAnimation.value,
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              color: Colors.white, // 더 밝은 배경색
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isPaused
                                      ? Colors.black.withOpacity(0.1)
                                      : AppColors.primaryColor.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 진행 원
                                SizedBox(
                                  width: 260,
                                  height: 260,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 8,
                                    backgroundColor:
                                        const Color(0xFFE0E0E0), // 더 밝은 배경색
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isPaused
                                          ? Colors.grey
                                          : AppColors.primaryColor,
                                    ),
                                  ),
                                ),

                                // 시간 표시
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatTime(remainingSeconds),
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: isPaused
                                            ? Colors.grey
                                            : Colors.black87, // 어두운 색상으로 변경
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isTimerCompleted
                                          ? '완료됨!'
                                          : (isPaused ? '일시정지됨' : '집중 중'),
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 16,
                                        color: isTimerCompleted
                                            ? Colors.green
                                            : (isPaused
                                                ? Colors.grey
                                                : AppColors.primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 하단 버튼
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 홈으로 가기 버튼 (이전의 취소 버튼)
                    GestureDetector(
                      onTap: _goToHome,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor, // 버튼 색상 통일
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),

                    // 일시정지/재개 버튼
                    GestureDetector(
                      onTap: _togglePauseResume,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              isPaused ? AppColors.primaryColor : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            color: isPaused
                                ? Colors.white
                                : AppColors.primaryColor,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),

                    // 완료 버튼 (타이머 완료 시에만 활성화)
                    GestureDetector(
                      onTap: isTimerCompleted ? _completeTimer : null,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isTimerCompleted
                              ? AppColors.successColor // 타이머 완료 시 녹색으로 변경
                              : Colors.grey[300], // 비활성화 시 회색
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check,
                            color: isTimerCompleted
                                ? Colors.white
                                : Colors.grey[500],
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
