// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:launch/views/home/widgets/activity_list_item..dart';
import 'package:provider/provider.dart';
import 'package:launch/core/constant/colors.dart';
import 'package:launch/viewmodels/auth_viewmodel.dart';
import 'package:launch/viewmodels/activity_viewmodel.dart';
import 'package:launch/viewmodels/profile_viewmodel.dart';
import 'package:launch/views/widgets/app_button.dart';
import 'package:launch/views/home/widgets/progress_circle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 앱이 포그라운드로 돌아올 때 데이터 새로고침
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 마지막 갱신 후 5분이 지났으면 데이터 다시 로드
      final now = DateTime.now();
      if (_lastRefreshTime == null ||
          now.difference(_lastRefreshTime!).inMinutes >= 5) {
        _loadData();
      }
    }
  }

  // 데이터 로드
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final activityViewModel =
        Provider.of<ActivityViewModel>(context, listen: false);
    final profileViewModel =
        Provider.of<ProfileViewModel>(context, listen: false);

    if (authViewModel.user != null) {
      final userId = authViewModel.user!.uid;

      try {
        // 활동 및 프로필 데이터 로드
        await Future.wait([
          activityViewModel.loadUserActivities(userId),
          profileViewModel.loadUserProfile(userId),
        ]);

        // 마지막 갱신 시간 기록
        _lastRefreshTime = DateTime.now();
      } catch (e) {
        print('데이터 로드 오류: $e');
        // 오류 발생 시에도 로딩 상태 종료
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 수동 새로고침
  Future<void> _refreshData() async {
    await _loadData();
    // 새로고침 완료 메시지 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새로고침 완료'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // 카운트다운 화면으로 이동
  // HomeScreen.dart - _navigateToCountdown 메서드 수정
  void _navigateToCountdown() async {
    final activityViewModel =
        Provider.of<ActivityViewModel>(context, listen: false);
    final profileViewModel =
        Provider.of<ProfileViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    if (activityViewModel.selectedActivity == null) {
      // 선택된 활동이 없으면 활동 선택 화면으로 이동
      Navigator.of(context).pushNamed('/activity_selection');
    } else {
      // 선택된 활동이 있으면 카운트다운 화면으로 이동
      final result = await Navigator.of(context).pushNamed('/countdown');

      // 결과 로그 추가 (디버깅용)
      print('카운트다운 결과: $result');

      // 활동이 완료되었을 경우 통계 업데이트
      if (result == true && authViewModel.user != null) {
        print('활동 완료됨: HomeScreen에서 통계 업데이트 시작');

        // 이미 CountdownScreen에서 업데이트했을 수 있지만, 안전하게 한번 더 확인
        await profileViewModel
            .updateStatisticsAfterActivityCompletion(authViewModel.user!.uid);

        // 화면 새로고침
        await _refreshData();

        // 사용자에게 피드백 제공
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('활동이 완료되었습니다! 통계가 업데이트되었습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  // 활동 선택 화면으로 이동
  void _navigateToActivitySelection() {
    Navigator.of(context).pushNamed('/activity_selection');
  }

  // 프로필 화면으로 이동
  void _navigateToProfile() {
    Navigator.of(context).pushNamed('/profile');
  }

  // 로그아웃
  Future<void> _signOut() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.signOut();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final activityViewModel = Provider.of<ActivityViewModel>(context);
    final profileViewModel = Provider.of<ProfileViewModel>(context);

    final activities = activityViewModel.activities;
    final selectedActivity = activityViewModel.selectedActivity;
    final userProfile = profileViewModel.userProfile;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.primaryColor,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 헤더
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 로고 및 앱 이름
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "10",
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "LAUNCH MODE",
                                  style: TextStyle(
                                    fontFamily: 'jua',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),

                            // 새로고침 및 프로필 아이콘
                            Row(
                              children: [
                                // 프로필 아이콘
                                GestureDetector(
                                  onTap: _navigateToProfile,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: authViewModel.user?.photoURL !=
                                              null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Image.network(
                                                authViewModel.user!.photoURL!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(
                                                    Icons.person,
                                                    color: Colors.black87,
                                                    size: 20,
                                                  );
                                                },
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              color: Colors.black87,
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 메인 컨텐츠
                      Expanded(
                        child: SingleChildScrollView(
                          physics:
                              const AlwaysScrollableScrollPhysics(), // 항상 스크롤 가능하도록 설정 (RefreshIndicator 때문)
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 사용자 환영 메시지
                              Text(
                                '안녕하세요, ${authViewModel.user?.displayName ?? '사용자'}님!',
                                style: const TextStyle(
                                  fontFamily: 'jua',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '오늘도 10초의 법칙으로 시작해보세요.',
                                style: TextStyle(
                                  fontFamily: 'jua',
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // 진행 상황 카드
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    // 완료 정보
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // 완료 활동 수
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '오늘의 완료',
                                              style: TextStyle(
                                                fontFamily: 'jua',
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.baseline,
                                              textBaseline:
                                                  TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  '${profileViewModel.totalCompletedActivities}',
                                                  style: const TextStyle(
                                                    fontFamily: 'jua',
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '활동',
                                                  style: TextStyle(
                                                    fontFamily: 'jua',
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        // 연속 일수
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '연속 일수',
                                              style: TextStyle(
                                                fontFamily: 'jua',
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.baseline,
                                              textBaseline:
                                                  TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  '${profileViewModel.streak}',
                                                  style: const TextStyle(
                                                    fontFamily: 'jua',
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors
                                                        .energeticColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '일',
                                                  style: TextStyle(
                                                    fontFamily: 'jua',
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // 진행 상황 그래프
                                    const Text(
                                      '이번 주 진행 상황',
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // 요일별 진행 상황
                                    SizedBox(
                                      height: 60,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildDayProgress(
                                              'monday', '월', profileViewModel),
                                          _buildDayProgress(
                                              'tuesday', '화', profileViewModel),
                                          _buildDayProgress('wednesday', '수',
                                              profileViewModel),
                                          _buildDayProgress('thursday', '목',
                                              profileViewModel),
                                          _buildDayProgress(
                                              'friday', '금', profileViewModel),
                                          _buildDayProgress('saturday', '토',
                                              profileViewModel),
                                          _buildDayProgress(
                                              'sunday', '일', profileViewModel),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // 카운트다운 섹션
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 타이틀
                                    const Text(
                                      '10초의 법칙',
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '카운트다운 후 바로 시작하세요!',
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // 선택된 활동 정보
                                    if (selectedActivity != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            // 활동 아이콘
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  selectedActivity.emoji,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // 활동 정보
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    selectedActivity.name,
                                                    style: const TextStyle(
                                                      fontFamily: 'jua',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Text(
                                                    selectedActivity
                                                        .description,
                                                    style: TextStyle(
                                                      fontFamily: 'jua',
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // 변경 버튼
                                            TextButton(
                                              onPressed:
                                                  _navigateToActivitySelection,
                                              child: const Text(
                                                '변경',
                                                style: TextStyle(
                                                  fontFamily: 'jua',
                                                  color: AppColors.primaryColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // 시작 버튼
                                    AppButton(
                                      text: 'LAUNCH',
                                      onPressed: _navigateToCountdown,
                                      backgroundColor: AppColors.primaryColor,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // 내 활동 목록
                              const Text(
                                '내 활동',
                                style: TextStyle(
                                  fontFamily: 'jua',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 활동 목록
                              if (activities.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      '등록된 활동이 없습니다.',
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: activities.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final activity = activities[index];
                                    return ActivityListItem(
                                      activity: activity,
                                      isSelected:
                                          selectedActivity?.id == activity.id,
                                      onTap: () {
                                        activityViewModel
                                            .selectActivity(activity);
                                      },
                                    );
                                  },
                                ),

                              const SizedBox(height: 16),

                              // 새 활동 추가 버튼
                              AppButton(
                                text: '새 활동 추가',
                                onPressed: _navigateToActivitySelection,
                                backgroundColor: Colors.transparent,
                                textColor: AppColors.primaryColor,
                                borderRadius: 12,
                                height: 45,
                              ),

                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // 요일별 진행 상황 위젯
  Widget _buildDayProgress(
      String dayName, String dayLabel, ProfileViewModel profileViewModel) {
    final count = profileViewModel.weeklyProgress[dayName] ?? 0;
    final bool isToday = _getDayName(DateTime.now().weekday) == dayName;

    return Column(
      children: [
        // 진행 상태 원
        ProgressCircle(
          progress: count > 0 ? 1.0 : 0.0,
          size: 32,
          lineWidth: 3,
          color: count > 0
              ? AppColors.progressColor
              : isToday
                  ? AppColors.primaryColor.withOpacity(0.3)
                  : Colors.grey[800]!,
          backgroundColor: Colors.grey[850]!,
          child: count > 0
              ? const Icon(
                  Icons.check,
                  color: AppColors.progressColor,
                  size: 16,
                )
              : null,
        ),
        const SizedBox(height: 8),

        // 요일 라벨
        Text(
          dayLabel,
          style: TextStyle(
            fontFamily: 'jua',
            fontSize: 14,
            color: isToday ? AppColors.primaryColor : Colors.black87,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // 요일 이름 반환
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
}
