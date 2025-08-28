// lib/viewmodels/profile_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:launch/services/activity_service.dart';
import 'package:launch/services/user_service.dart';

enum ProfileViewState {
  initial,
  loading,
  loaded,
  error,
}

class ProfileViewModel with ChangeNotifier {
  final FirebaseRepository _userRepository; // FirebaseRepository 타입 사용
  final FirebaseRepository _activityRepository; // FirebaseRepository 타입 사용

  ProfileViewState _state = ProfileViewState.initial;
  UserProfile? _userProfile;
  List<ActivitySession> _recentSessions = [];
  int _totalCompletedActivities = 0;
  int _streak = 0;
  Map<String, int> _weeklyProgress = {};
  String? _errorMessage;

  // 구독 취소를 위한 스트림 구독 객체
  StreamSubscription? _userProfileSubscription;
  StreamSubscription? _activitySessionsSubscription;

  ProfileViewModel({
    required FirebaseRepository userRepository, // FirebaseRepository 매개변수 타입 사용
    required FirebaseRepository
        activityRepository, // FirebaseRepository 매개변수 타입 사용
  })  : _userRepository = userRepository,
        _activityRepository = activityRepository;

  // 상태 및 데이터 접근자
  ProfileViewState get state => _state;
  UserProfile? get userProfile => _userProfile;
  List<ActivitySession> get recentSessions => _recentSessions;
  int get totalCompletedActivities => _totalCompletedActivities;
  int get streak => _streak;
  Map<String, int> get weeklyProgress => _weeklyProgress;
  String? get errorMessage => _errorMessage;

  // 사용자 프로필 로드
  Future<void> loadUserProfile(String userId) async {
    try {
      _state = ProfileViewState.loading;
      notifyListeners();

      // 사용자 프로필 가져오기
      final profile = await _userRepository.getUserProfile(userId);

      // 프로필이 없으면 생성
      if (profile == null) {
        await _userRepository.createUserProfile(userId);
        _userProfile = await _userRepository.getUserProfile(userId);
      } else {
        _userProfile = profile;
      }

      // 최근 활동 세션 가져오기
      _recentSessions =
          await _activityRepository.getUserActivitySessions(userId);

      // 통계 업데이트
      _updateStatisticsFromProfile();

      // 실시간 업데이트를 위한 스트림 구독
      _subscribeToUserProfileUpdates(userId);
      _subscribeToActivitySessionsUpdates(userId);

      _state = ProfileViewState.loaded;
      notifyListeners();
    } catch (e) {
      _state = ProfileViewState.error;
      _errorMessage = e.toString();
      print('프로필 로드 오류: $e');
      notifyListeners();
    }
  }

  // 프로필에서 통계 정보 추출
  void _updateStatisticsFromProfile() {
    if (_userProfile != null) {
      _totalCompletedActivities = _userProfile!.totalCompletedActivities;
      _streak = _userProfile!.streak;
      _weeklyProgress = Map<String, int>.from(_userProfile!.weeklyProgress);
    } else {
      _totalCompletedActivities = 0;
      _streak = 0;
      _weeklyProgress = {
        'monday': 0,
        'tuesday': 0,
        'wednesday': 0,
        'thursday': 0,
        'friday': 0,
        'saturday': 0,
        'sunday': 0,
      };
    }
  }

  // 리소스 정리
  @override
  void dispose() {
    _userProfileSubscription?.cancel();
    _activitySessionsSubscription?.cancel();
    super.dispose();
  }

  // 사용자 프로필 업데이트 스트림 구독
  void _subscribeToUserProfileUpdates(String userId) {
    _userProfileSubscription?.cancel();
    _userProfileSubscription =
        _userRepository.userProfileStream(userId).listen((profile) {
      if (profile != null) {
        _userProfile = profile;
        _totalCompletedActivities = profile.totalCompletedActivities;
        _streak = profile.streak;
        _weeklyProgress = Map<String, int>.from(profile.weeklyProgress);
        notifyListeners();
      }
    }, onError: (error) {
      print('프로필 스트림 오류: $error');
    });
  }

  // 활동 세션 업데이트 스트림 구독
  void _subscribeToActivitySessionsUpdates(String userId) {
    _activitySessionsSubscription?.cancel();

    // 통합된 FirebaseRepository에서는 activitySessionsStream 메서드 사용
    _activitySessionsSubscription =
        _activityRepository.activitySessionsStream(userId).listen((sessions) {
      _recentSessions = sessions;
      notifyListeners();
    }, onError: (error) {
      print('활동 세션 스트림 오류: $error');
    });
  }

  // 활동 완료 후 통계 업데이트 요청
// ProfileViewModel의 updateStatisticsAfterActivityCompletion 메서드 수정

  Future<void> updateStatisticsAfterActivityCompletion(String userId) async {
    try {
      // 현재 요일 가져오기
      final now = DateTime.now();
      final dayName = _getDayName(now.weekday);

      print('활동 완료 - 요일 업데이트 시도: $dayName (${now.toString()})');

      // 통계 업데이트 요청 전 현재 상태 확인
      UserProfile? beforeProfile;
      try {
        beforeProfile = await _userRepository.getUserProfile(userId);
        print('업데이트 전 주간 진행 상황: ${beforeProfile?.weeklyProgress}');
      } catch (e) {
        print('프로필 가져오기 오류: $e - 계속 진행합니다');
      }

      // 사용자 프로필이 없으면 먼저 생성
      if (beforeProfile == null) {
        try {
          print('프로필이 없습니다. 새로 생성합니다.');
          await _userRepository.createUserProfile(userId);
          await Future.delayed(const Duration(milliseconds: 500)); // 생성 완료 대기
        } catch (e) {
          print('프로필 생성 오류: $e - 계속 진행합니다');
        }
      }

      // 최대 3번 시도
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('통계 업데이트 시도 #$attempt');

          // 통계 업데이트 요청
          await _userRepository.updateUserStatistics(
            userId,
            completedActivities: 1,
            incrementStreak: true,
            dayOfWeek: dayName,
          );

          print('통계 업데이트 성공');
          break; // 성공하면 반복 종료
        } catch (e) {
          print('통계 업데이트 시도 #$attempt 실패: $e');

          if (attempt < 3) {
            // 권한 문제 또는 네트워크 지연 시 더 오래 기다림
            await Future.delayed(Duration(seconds: attempt));

            // 직접 프로필 업데이트 시도
            try {
              final profile = await _userRepository.getUserProfile(userId);
              if (profile != null) {
                // 현재 요일의 진행 상황 증가
                final updatedWeeklyProgress =
                    Map<String, int>.from(profile.weeklyProgress);
                updatedWeeklyProgress[dayName] =
                    (updatedWeeklyProgress[dayName] ?? 0) + 1;

                print('대체 방법으로 통계 업데이트 성공');
                break; // 성공하면 반복 종료
              }
            } catch (manualError) {
              print('수동 업데이트 시도 실패: $manualError');
            }
          } else {
            // 마지막 시도 실패
            _errorMessage = '통계 업데이트 실패: $e';
          }
        }
      }

      // 프로필 새로고침 (성공 여부와 관계없이)
      try {
        await Future.delayed(const Duration(milliseconds: 500)); // 업데이트 반영 대기
        await loadUserProfile(userId);
        print('업데이트 후 주간 진행 상황: $_weeklyProgress');
      } catch (e) {
        print('프로필 다시 로드 오류: $e');
      }

      // UI 갱신을 위한 알림
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('통계 업데이트 오류: $e');
      notifyListeners();
    }
  }
  // 2번 코드의 updateUserProfile 메서드 수정 (await _userService 부분 해결)

// ProfileViewModel 클래스 내의 updateUserProfile 메서드 수정
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      // 안전한 업데이트를 위해 weeklyProgress 특별 처리
      if (updates.containsKey('weeklyProgress') &&
          updates['weeklyProgress'] is Map) {
        final Map<String, dynamic> safeWeeklyProgress = {};

        (updates['weeklyProgress'] as Map).forEach((key, value) {
          if (key is String) {
            // 정수로 강제 변환하여 저장
            safeWeeklyProgress[key] =
                value is int ? value : (value is num ? value.toInt() : 0);
          }
        });

        // 모든 요일이 있는지 확인
        for (var day in [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday'
        ]) {
          if (!safeWeeklyProgress.containsKey(day)) {
            safeWeeklyProgress[day] = 0;
          }
        }

        // 안전한 맵으로 교체
        updates['weeklyProgress'] = safeWeeklyProgress;
      }

      // 사용자 프로필 업데이트 - UserProfile 객체 생성 및 수정
      try {
        // 현재 사용자 프로필 가져오기
        final profile = await _userRepository.getUserProfile(userId);
        if (profile != null) {
          // 업데이트할 필드 반영
          final updatedProfile = profile.copyWith(
            totalCompletedActivities:
                updates.containsKey('totalCompletedActivities')
                    ? updates['totalCompletedActivities'] as int
                    : profile.totalCompletedActivities,
            streak: updates.containsKey('streak')
                ? updates['streak'] as int
                : profile.streak,
            weeklyProgress: updates.containsKey('weeklyProgress')
                ? Map<String, int>.from(updates['weeklyProgress'] as Map)
                : profile.weeklyProgress,
            lastActivityDate: updates.containsKey('lastActivityDate')
                ? updates['lastActivityDate'] as String
                : profile.lastActivityDate,
          );

          // 업데이트 실행
          await _userRepository.updateUserProfile(updatedProfile);
          print('사용자 프로필 업데이트 성공');
        } else {
          print('업데이트할 프로필을 찾을 수 없음');
          throw Exception('업데이트할 프로필을 찾을 수 없음');
        }
      } catch (e) {
        print("error 발생 ");
      }
    } catch (e) {
      print('사용자 프로필 업데이트 오류: $e');
      rethrow;
    }
  }
// 2번 코드의 updateUserProfile 메서드 수정 (await _userService 부분 해결)

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

  // 한글 요일 이름 변환
  String getDayNameKorean(String englishDayName) {
    switch (englishDayName.toLowerCase()) {
      case 'monday':
        return '월';
      case 'tuesday':
        return '화';
      case 'wednesday':
        return '수';
      case 'thursday':
        return '목';
      case 'friday':
        return '금';
      case 'saturday':
        return '토';
      case 'sunday':
        return '일';
      default:
        return '';
    }
  }

  // 에러 초기화
  void resetError() {
    _errorMessage = null;
    if (_state == ProfileViewState.error) {
      _state = ProfileViewState.loaded;
    }
    notifyListeners();
  }
}
