// lib/viewmodels/activity_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:launch/services/activity_service.dart';
import 'package:launch/services/user_service.dart';

enum ActivityViewState {
  initial,
  loading,
  loaded,
  error,
}

class ActivityViewModel with ChangeNotifier {
  final FirebaseRepository _activityRepository;

  ActivityViewState _state = ActivityViewState.initial;
  List<Activity> _activities = [];
  Activity? _selectedActivity;
  String? _errorMessage;

  ActivityViewModel({
    required FirebaseRepository activityRepository,
  }) : _activityRepository = activityRepository;

  // 상태 및 데이터 접근자
  ActivityViewState get state => _state;
  List<Activity> get activities => _activities;
  Activity? get selectedActivity => _selectedActivity;
  String? get errorMessage => _errorMessage;

  // 사용자별 활동 로드
  Future<void> loadUserActivities(String userId) async {
    // 이미 로딩 중이면 중복 호출 방지
    if (_state == ActivityViewState.loading) return;

    try {
      // 상태 변경 및 알림
      _state = ActivityViewState.loading;
      notifyListeners();

      // 별도의 비동기 처리를 위한 마이크로태스크 큐에 작업 추가
      await Future.microtask(() => null);

      // 나머지 코드...
      final hasDefaultActivities =
          await _activityRepository.hasDefaultActivities(userId);

      if (!hasDefaultActivities) {
        await _activityRepository.createDefaultActivities(userId);
      }

      _activities = await _activityRepository.getUserActivities(userId);

      if (_selectedActivity == null && _activities.isNotEmpty) {
        _selectedActivity = _activities.first;
      }

      // 최종 상태 업데이트
      _state = ActivityViewState.loaded;
      notifyListeners();
    } catch (e) {
      _state = ActivityViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // 활동 선택
  void selectActivity(Activity activity) {
    _selectedActivity = activity;
    notifyListeners();
  }

  // 활동 선택 (ID로)
  Future<void> selectActivityById(String activityId) async {
    try {
      // 이미 로드된 활동 중에서 찾기
      final activity = _activities.firstWhere(
        (element) => element.id == activityId,
        orElse: () => throw Exception('Activity not found'),
      );

      _selectedActivity = activity;
      notifyListeners();
    } catch (e) {
      // 로드된 활동에 없으면 서버에서 가져오기
      try {
        final activity = await _activityRepository.getActivity(activityId);
        _selectedActivity = activity;
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Activity not found';
        notifyListeners();
      }
    }
  }

  // 새 활동 생성
  Future<Activity?> createActivity(Activity activity) async {
    try {
      _state = ActivityViewState.loading;
      notifyListeners();

      final newActivity = await _activityRepository.createActivity(activity);

      // 활동 목록에 추가
      _activities.add(newActivity);

      // 현재 선택된 활동으로 설정
      _selectedActivity = newActivity;

      _state = ActivityViewState.loaded;
      notifyListeners();

      return newActivity;
    } catch (e) {
      _state = ActivityViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // 활동 업데이트
  Future<bool> updateActivity(Activity activity) async {
    try {
      _state = ActivityViewState.loading;
      notifyListeners();

      await _activityRepository.updateActivity(activity);

      // 목록에서 해당 활동 갱신
      final index = _activities.indexWhere((a) => a.id == activity.id);
      if (index != -1) {
        _activities[index] = activity;
      }

      // 선택된 활동이면 갱신
      if (_selectedActivity?.id == activity.id) {
        _selectedActivity = activity;
      }

      _state = ActivityViewState.loaded;
      notifyListeners();

      return true;
    } catch (e) {
      _state = ActivityViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 활동 삭제
  Future<bool> deleteActivity(String activityId) async {
    try {
      _state = ActivityViewState.loading;
      notifyListeners();

      await _activityRepository.deleteActivity(activityId);

      // 목록에서 해당 활동 삭제
      _activities.removeWhere((activity) => activity.id == activityId);

      // 선택된 활동이면 선택 해제
      if (_selectedActivity?.id == activityId) {
        _selectedActivity = _activities.isNotEmpty ? _activities.first : null;
      }

      _state = ActivityViewState.loaded;
      notifyListeners();

      return true;
    } catch (e) {
      _state = ActivityViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 완료 횟수 증가
  Future<bool> incrementCompletionCount(String activityId) async {
    try {
      await _activityRepository.incrementCompletionCount(activityId);

      // 목록에서 해당 활동 찾기
      final index = _activities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        // 완료 횟수가 Activity 모델에 포함되어 있지 않으므로, 전체 활동을 다시 가져오는 것이 안전합니다.
        // 만약 completionCount 필드가 있다면 아래 주석 해제
        /*
        // 완료 횟수 증가
        final updatedActivity = _activities[index].copyWith(
          completionCount: _activities[index].completionCount + 1,
        );

        // 목록 갱신
        _activities[index] = updatedActivity;

        // 선택된 활동이면 갱신
        if (_selectedActivity?.id == activityId) {
          _selectedActivity = updatedActivity;
        }
        */

        // 활동 목록을 다시 로드하는 것이 더 안전합니다.
        if (_activities.isNotEmpty) {
          await loadUserActivities(_activities[0].userId);
        }

        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 활동 세션 생성
  Future<ActivitySession?> createActivitySession(Activity activity) async {
    try {
      final now = DateTime.now();

      // 새 세션 생성
      final session = ActivitySession(
        id: '',
        activityId: activity.id,
        userId: activity.userId,
        startTime: now,
        duration: Duration(minutes: activity.durationMinutes),
        completed: false,
      );

      // 저장소에 세션 생성
      final createdSession =
          await _activityRepository.createActivitySession(session);

      return createdSession;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // 활동 세션 완료
  Future<bool> completeActivitySession(String sessionId) async {
    try {
      await _activityRepository.completeActivitySession(sessionId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 에러 초기화
  void resetError() {
    _errorMessage = null;
    if (_state == ActivityViewState.error) {
      _state = ActivityViewState.loaded;
    }
    notifyListeners();
  }

  // 사용자 활동 스트림 설정
  Stream<List<Activity>> userActivitiesStream(String userId) {
    return _activityRepository.userActivitiesStream(userId);
  }
}
