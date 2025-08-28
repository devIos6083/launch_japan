// lib/viewmodels/timer_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:launch/services/activity_service.dart';
import 'package:launch/services/user_service.dart';
import 'package:launch/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart'; // BuildContext를 위해 추가

enum FocusTimerState {
  initial,
  running,
  paused,
  completed,
}

class TimerViewModel with ChangeNotifier {
  final TimerService _timerService;
  final FirebaseRepository _activityRepository; // FirebaseRepository 타입 사용
  ProfileViewModel? _profileViewModel; // Provider를 통해 가져올 예정
  BuildContext? _context; // Provider 접근을 위한 context

  FocusTimerState _state = FocusTimerState.initial;
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  Activity? _currentActivity;
  ActivitySession? _currentSession;
  String? _errorMessage;
  StreamSubscription<TimerState>? _timerSubscription;
  bool _statisticsUpdated = false; // 통계 업데이트 여부 추적

  TimerViewModel({
    required TimerService timerService,
    required FirebaseRepository
        activityRepository, // FirebaseRepository 매개변수 타입 사용
  })  : _timerService = timerService,
        _activityRepository = activityRepository {
    _initTimerListener();
  }

  // context 설정 메서드 추가
  void setContext(BuildContext context) {
    _context = context;
  }

  // 상태 및 데이터 접근자
  FocusTimerState get state => _state;
  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  Activity? get currentActivity => _currentActivity;
  ActivitySession? get currentSession => _currentSession;
  String? get errorMessage => _errorMessage;
  bool get statisticsUpdated => _statisticsUpdated;

  double get progress => _totalSeconds > 0
      ? ((_totalSeconds - _remainingSeconds) / _totalSeconds)
      : 0.0;
  String get formattedTime => _formatTime(_remainingSeconds);
  bool get isRunning => _state == FocusTimerState.running;
  bool get isPaused => _state == FocusTimerState.paused;

  // 타이머 리스너 초기화
  void _initTimerListener() {
    _timerSubscription = _timerService.focusTimerStream.listen((timerState) {
      _totalSeconds = timerState.totalSeconds;
      _remainingSeconds = timerState.remainingSeconds;
      _currentSession = timerState.currentSession != null
          ? ActivitySession(
              id: timerState.currentSession!.id,
              userId: timerState.currentSession!.userId,
              activityId: timerState.currentSession!.activityId,
              startTime: timerState.currentSession!.startTime,
              endTime: timerState.currentSession!.endTime,
              completed: timerState.currentSession!.isCompleted,
              duration: Duration(seconds: timerState.totalSeconds),
            )
          : null;

      if (timerState.isRunning) {
        _state = timerState.isPaused
            ? FocusTimerState.paused
            : FocusTimerState.running;
      } else {
        _state = _remainingSeconds <= 0
            ? FocusTimerState.completed
            : FocusTimerState.initial;
      }

      notifyListeners();
    });
  }

  // 집중 타이머 시작
  Future<bool> startFocusTimer(Activity activity) async {
    try {
      _errorMessage = null;
      _currentActivity = activity;
      _statisticsUpdated = false; // 새 타이머 시작 시 상태 초기화

      // 타이머 서비스로 타이머 시작
      await _timerService.startFocusTimer(activity);

      // 활동 세션 생성
      final createdSession = await _activityRepository.createActivitySession(
        ActivitySession(
          id: '',
          activityId: activity.id,
          userId: activity.userId,
          startTime: DateTime.now(),
          duration: Duration(minutes: activity.durationMinutes),
          completed: false,
        ),
      );

      _currentSession = createdSession;
      _state = FocusTimerState.running;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('타이머 시작 오류: $e');
      notifyListeners();
      return false;
    }
  }

  // 타이머 일시정지
  Future<void> pauseTimer() async {
    try {
      await _timerService.pauseFocusTimer();
      _state = FocusTimerState.paused;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('타이머 일시정지 오류: $e');
      notifyListeners();
    }
  }

  // 타이머 재개
  Future<void> resumeTimer() async {
    try {
      await _timerService.resumeFocusTimer();
      _state = FocusTimerState.running;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('타이머 재개 오류: $e');
      notifyListeners();
    }
  }

  // 타이머 중지
  Future<void> stopTimer() async {
    try {
      await _timerService.stopFocusTimer();
      _state = FocusTimerState.initial;
      _currentActivity = null;
      _currentSession = null;
      _statisticsUpdated = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('타이머 중지 오류: $e');
      notifyListeners();
    }
  }

  // 타이머 완료
  Future<bool> completeTimer() async {
    try {
      await _timerService.completeFocusTimer();

      // 활동 세션 완료 처리
      if (_currentSession != null) {
        print('세션 완료 시작: ${_currentSession!.id}');

        // 세션 ID 검증 ('temp_id'이거나 비어있으면 완료 프로세스를 건너뛰지만 함수는 성공 반환)
        if (_currentSession!.id.isEmpty || _currentSession!.id == 'temp_id') {
          print('유효하지 않은 세션 ID (${_currentSession!.id}) - 세션 업데이트 건너뜀');

          // 활동 완료 횟수는 여전히 증가시킵니다 (세션과 독립적으로)
          if (_currentActivity != null && _currentActivity!.id.isNotEmpty) {
            try {
              print('활동 카운트 직접 증가 시작: ${_currentActivity!.id}');
              await _activityRepository
                  .incrementCompletionCount(_currentActivity!.id);
              print('활동 카운트 증가 성공');

              // 프로필 통계 업데이트
              if (_currentActivity!.userId.isNotEmpty) {
                await _updateProfileStatistics(_currentActivity!.userId);
              }
            } catch (e) {
              print('활동 카운트 증가 오류 (무시): $e');
            }
          }
        } else {
          // 정상적인 세션 ID가 있는 경우 표준 완료 프로세스 진행
          try {
            await _activityRepository
                .completeActivitySession(_currentSession!.id);
            print('세션 완료 처리 성공');
          } catch (e) {
            print('세션 완료 처리 오류 (무시): $e');

            // 세션 완료에 실패하더라도 활동 완료 횟수는 증가시킴
            if (_currentActivity != null && _currentActivity!.id.isNotEmpty) {
              try {
                print('활동 카운트 대체 증가 시작: ${_currentActivity!.id}');
                await _activityRepository
                    .incrementCompletionCount(_currentActivity!.id);
                print('활동 카운트 증가 성공');
              } catch (activityErr) {
                print('활동 카운트 증가 오류: $activityErr');
              }
            }
          }

          // 프로필 통계 업데이트 (세션 완료 성공 여부와 관계없이)
          if (_currentActivity != null && _currentActivity!.userId.isNotEmpty) {
            await _updateProfileStatistics(_currentActivity!.userId);
          }
        }
      } else {
        print('세션이 null입니다 - 세션 완료 및 활동 카운트 증가를 건너뜀');
      }

      _state = FocusTimerState.completed;
      _statisticsUpdated = true;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('타이머 완료 처리 오류: $e');
      notifyListeners();
      return false;
    }
  }

  // 프로필 통계 업데이트 메서드 (개선됨)
  Future<void> _updateProfileStatistics(String userId) async {
    try {
      print('프로필 통계 업데이트 시작: $userId');

      // Context를 통해 ProfileViewModel 가져오기
      if (_context != null) {
        try {
          final profileViewModel =
              Provider.of<ProfileViewModel>(_context!, listen: false);

          // 프로필 데이터 새로고침
          await profileViewModel.loadUserProfile(userId);

          print('프로필 통계 업데이트 성공');
          _statisticsUpdated = true;
          notifyListeners();
        } catch (providerError) {
          print('Provider에서 ProfileViewModel을 가져오는 중 오류 (무시): $providerError');
          // 대체 방법으로 직접 통계 업데이트 시도
          await _updateStatisticsDirectly(userId);
        }
      } else {
        print('Context가 없어 직접 프로필 통계를 업데이트합니다');
        await _updateStatisticsDirectly(userId);
      }
    } catch (e) {
      print('프로필 통계 업데이트 오류: $e');
      // 오류가 발생해도 타이머 완료 자체는 성공으로 처리
    }
  }

  // TimerViewModel.dart - _updateStatisticsDirectly 메서드 확인/수정
  Future<void> _updateStatisticsDirectly(String userId) async {
    try {
      print('직접 통계 업데이트 시도');
      final today = DateTime.now();
      final dayName = _getDayName(today.weekday);

      // 요일 이름을 로그에 기록하여 확인
      print('현재 요일 ($dayName) 업데이트 시도: ${today.toString()}');

      // FirebaseRepository를 통해 직접 통계 업데이트
      await _activityRepository.updateUserStatistics(
        userId,
        completedActivities: 1,
        incrementStreak: true,
        dayOfWeek: dayName,
      );

      print('직접 통계 업데이트 완료');
      _statisticsUpdated = true;
      notifyListeners();
    } catch (e) {
      print('직접 통계 업데이트 오류: $e');
    }
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

  // 타이머 재설정
  void resetTimer() {
    _state = FocusTimerState.initial;
    _totalSeconds = 0;
    _remainingSeconds = 0;
    _currentActivity = null;
    _currentSession = null;
    _statisticsUpdated = false;
    notifyListeners();
  }

  // 시간 포맷팅 (MM:SS)
  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 에러 초기화
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 리소스 해제
  @override
  void dispose() {
    _timerSubscription?.cancel();
    super.dispose();
  }
}
