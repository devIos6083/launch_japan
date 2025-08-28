// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:launch/services/activity_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:launch/core/constant/colors.dart';

import 'package:launch/viewmodels/auth_viewmodel.dart';
import 'package:launch/viewmodels/profile_viewmodel.dart';
import 'package:launch/viewmodels/activity_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, Activity> _activitiesMap = {}; // 활동 ID와 활동 객체 매핑을 위한 맵

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  // 사용자 프로필 및 활동 목록 로드
  Future<void> _loadUserProfile() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final profileViewModel =
        Provider.of<ProfileViewModel>(context, listen: false);
    final activityViewModel =
        Provider.of<ActivityViewModel>(context, listen: false);

    if (authViewModel.user != null) {
      final userId = authViewModel.user!.uid;

      // 프로필 로드
      await profileViewModel.loadUserProfile(userId);

      // 활동 목록 로드
      await activityViewModel.loadUserActivities(userId);

      // 활동 ID를 활동 이름으로 매핑하기 위한 맵 생성
      setState(() {
        _activitiesMap = {
          for (var activity in activityViewModel.activities)
            activity.id: activity
        };
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 활동 ID로 활동 이름 가져오기
  String _getActivityName(String activityId) {
    // 1. 활동 맵에서 활동 찾기
    final activity = _activitiesMap[activityId];

    // 2. 활동이 있으면 name 반환, 없으면 activityId 자체를 문자열로 보여줌
    if (activity != null) {
      // name 필드가 있으면 그것을 사용, 없으면 activityId 사용
      return activity.name.isNotEmpty ? activity.name : '활동 $activityId';
    }

    return '알 수 없는 활동';
  }

  // 활동 ID로 활동 이모지 가져오기
  String _getActivityEmoji(String activityId) {
    // 1. 활동 맵에서 활동 찾기
    final activity = _activitiesMap[activityId];

    // 2. 활동이 있으면 emoji 반환, 없으면 기본 이모지
    if (activity != null) {
      // emoji 필드가 있으면 그것을 사용, 없으면 기본 이모지
      return activity.emoji.isNotEmpty ? activity.emoji : '❓';
    }

    return '❓';
  }

  // 로그아웃
  Future<void> _signOut() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.signOut();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  // 로그아웃 확인 다이얼로그
  Future<void> _showSignOutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          title: const Text(
            '로그아웃',
            style: TextStyle(
              fontFamily: 'jua',
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '정말 로그아웃 하시겠습니까?',
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
                  color: Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '로그아웃',
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
      await _signOut();
    }
  }

  // 날짜 포맷 (yyyy년 MM월 dd일)
  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date);
  }

  // 요일별 진행 상황 데이터 가져오기
  List<Map<String, dynamic>> _getWeeklyProgressData(
      ProfileViewModel profileViewModel) {
    final Map<String, int> weeklyProgress = profileViewModel.weeklyProgress;
    final List<String> dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    return dayNames.map((day) {
      return {
        'day': profileViewModel.getDayNameKorean(day),
        'count': weeklyProgress[day] ?? 0,
        'isToday': _getDayName(DateTime.now().weekday) == day,
      };
    }).toList();
  }

  // 요일 이름 반환
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

  // 새로고침 함수
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final profileViewModel = Provider.of<ProfileViewModel>(context);

    final user = authViewModel.user;
    final userProfile = profileViewModel.userProfile;
    final sessions = profileViewModel.recentSessions;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '내 프로필',
          style: TextStyle(
            fontFamily: 'jua',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.black87,
        ),
        actions: [
          // 로그아웃 버튼만 남기기
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showSignOutDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사용자 프로필 카드
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          // 프로필 이미지
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryColor,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: user?.photoURL != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Image.network(
                                        user!.photoURL!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Text(
                                            user.displayName?[0] ?? '?',
                                            style: const TextStyle(
                                              fontFamily: 'jua',
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Text(
                                      user?.displayName?[0] ?? '?',
                                      style: const TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // 사용자 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ?? '사용자',
                                  style: const TextStyle(
                                    fontFamily: 'jua',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    fontFamily: 'jua',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 가입일
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      userProfile != null
                                          ? '가입일: ${_formatDate(userProfile.createdAt)}'
                                          : '가입일: -',
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 통계 섹션
                    const Text(
                      '내 통계',
                      style: TextStyle(
                        fontFamily: 'jua',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 통계 카드들
                    Row(
                      children: [
                        // 총 완료 활동
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '완료한 활동',
                                  style: TextStyle(
                                    fontFamily: 'jua',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  profileViewModel.totalCompletedActivities
                                      .toString(),
                                  style: const TextStyle(
                                    fontFamily: 'jua',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 연속 일수
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '연속 일수',
                                  style: TextStyle(
                                    fontFamily: 'jua',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  profileViewModel.streak.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'jua',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.energeticColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 주간 활동 차트
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '주간 활동',
                            style: TextStyle(
                              fontFamily: 'jua',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 요일별 바 차트
                          SizedBox(
                            height: 180,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _getWeeklyProgressData(profileViewModel)
                                  .map((data) {
                                final int count = data['count'];
                                final bool isToday = data['isToday'];

                                // 최대 높이 설정
                                const maxHeight = 120.0;
                                // 최소 높이 설정 (0이라도 약간의 높이 표시)
                                final barHeight = count > 0
                                    ? (count * 30).clamp(20.0, maxHeight)
                                    : 5.0;

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // 활동 수 표시
                                    Text(
                                      count.toString(),
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: count > 0
                                            ? Colors.black87
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // 바 차트
                                    Container(
                                      width: 24,
                                      height: barHeight.toDouble(),
                                      decoration: BoxDecoration(
                                        color: count > 0
                                            ? AppColors.progressColor
                                            : isToday
                                                ? AppColors.primaryColor
                                                    .withOpacity(0.3)
                                                : Colors.grey[800],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // 요일 라벨
                                    Text(
                                      data['day'],
                                      style: TextStyle(
                                        fontFamily: 'jua',
                                        fontSize: 14,
                                        color: isToday
                                            ? AppColors.primaryColor
                                            : Colors.black87,
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 최근 활동 내역
                    const Text(
                      '최근 활동 내역',
                      style: TextStyle(
                        fontFamily: 'jua',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 활동 내역 리스트
                    sessions.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '최근 활동 내역이 없습니다.',
                                    style: TextStyle(
                                      fontFamily: 'jua',
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '첫 활동을 시작해보세요!',
                                    style: TextStyle(
                                      fontFamily: 'jua',
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                sessions.length > 5 ? 5 : sessions.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              final activityName =
                                  _getActivityName(session.activityId);
                              final activityEmoji =
                                  _getActivityEmoji(session.activityId);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    // 활동 상태 아이콘
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: session.completed
                                            ? AppColors.successColor
                                                .withOpacity(0.1)
                                            : Colors.grey[800],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          activityEmoji,
                                          style: const TextStyle(
                                            fontSize: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // 활동 정보
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activityName,
                                            style: const TextStyle(
                                              fontFamily: 'jua',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '시작: ${DateFormat('MM/dd HH:mm').format(session.startTime)}',
                                            style: TextStyle(
                                              fontFamily: 'jua',
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (session.endTime != null)
                                            Text(
                                              '종료: ${DateFormat('MM/dd HH:mm').format(session.endTime!)}',
                                              style: TextStyle(
                                                fontFamily: 'jua',
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // 활동 시간
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: session.completed
                                                ? AppColors.successColor
                                                    .withOpacity(0.1)
                                                : Colors.grey[800],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${session.duration.inMinutes}분',
                                            style: TextStyle(
                                              fontFamily: 'jua',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: session.completed
                                                  ? AppColors.successColor
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          session.completed ? '완료됨' : '진행 중',
                                          style: TextStyle(
                                            fontFamily: 'jua',
                                            fontSize: 12,
                                            color: session.completed
                                                ? AppColors.successColor
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
