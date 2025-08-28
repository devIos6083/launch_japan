import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:launch/services/activity_service.dart';

class TimerServiceImpl implements TimerService {
  // 알림 관련
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 오디오 플레이어
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 카운트다운 관련
  final StreamController<int> _countdownController =
      StreamController<int>.broadcast();
  Timer? _countdownTimer;
  bool _isCountdownRunning = false;

  // 집중 타이머 관련
  final StreamController<TimerState> _focusTimerController =
      StreamController<TimerState>.broadcast();
  Timer? _focusTimer;
  late TimerState _timerState;
  DateTime? _timerStartTime;
  DateTime? _timerPauseTime;

  // 소리 재생 활성화 여부
  final bool _enableSound = false; // 소리 비활성화

  TimerServiceImpl() {
    _timerState = TimerState();
    setupNotifications();
  }

  // 알림 설정
  @override
  Future<void> setupNotifications() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);
    } catch (e) {
      print('알림 설정 오류: $e');
    }
  }

  // 카운트다운 시작
  @override
  Future<void> startCountdown(int seconds) async {
    if (_isCountdownRunning) {
      await cancelCountdown();
    }

    _isCountdownRunning = true;
    int remaining = seconds;

    _countdownController.add(remaining);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;

      if (remaining <= 0) {
        timer.cancel();
        _isCountdownRunning = false;
        _countdownController.add(0);
        if (_enableSound) {
          _playSound('countdown_complete.mp3');
        }
      } else {
        _countdownController.add(remaining);
        if (remaining <= 3 && _enableSound) {
          _playSound('tick.mp3');
        }
      }
    });
  }

  // 카운트다운 취소
  @override
  Future<void> cancelCountdown() async {
    _countdownTimer?.cancel();
    _isCountdownRunning = false;
  }

  // 집중 타이머 시작
  @override
  Future<void> startFocusTimer(Activity activity) async {
    if (_timerState.isRunning) {
      await stopFocusTimer();
    }

    final durationSeconds = activity.durationMinutes * 60;
    _timerStartTime = DateTime.now();

    // 새 타이머 세션 생성 (ID는 임시로 설정)
    final session = activity.copyWith(
      id: 'temp_id', // 임시 ID 설정 (나중에 저장소에서 실제 ID로 대체됨)
      startTime: _timerStartTime!,
      isCompleted: false,
    );

    _timerState = TimerState(
      isRunning: true,
      isPaused: false,
      totalSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      currentSession: session,
    );

    _focusTimerController.add(_timerState);

    // 타이머 시작
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsedSeconds =
          DateTime.now().difference(_timerStartTime!).inSeconds;
      final remaining = durationSeconds - elapsedSeconds;

      if (remaining <= 0) {
        timer.cancel();
        completeFocusTimer();
      } else {
        _timerState = _timerState.copyWith(remainingSeconds: remaining);
        _focusTimerController.add(_timerState);
      }
    });
  }

  // 집중 타이머 일시정지
  @override
  Future<void> pauseFocusTimer() async {
    if (_timerState.isRunning && !_timerState.isPaused) {
      _focusTimer?.cancel();
      _timerPauseTime = DateTime.now();

      _timerState = _timerState.copyWith(isPaused: true);
      _focusTimerController.add(_timerState);
    }
  }

  // 집중 타이머 재개
  @override
  Future<void> resumeFocusTimer() async {
    if (_timerState.isRunning && _timerState.isPaused) {
      // 일시정지 시간만큼 시작 시간 조정
      final pauseDuration = DateTime.now().difference(_timerPauseTime!);
      _timerStartTime = _timerStartTime!.add(pauseDuration);

      _timerState = _timerState.copyWith(isPaused: false);
      _focusTimerController.add(_timerState);

      // 타이머 재시작
      _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final elapsedSeconds =
            DateTime.now().difference(_timerStartTime!).inSeconds;
        final remaining = _timerState.totalSeconds - elapsedSeconds;

        if (remaining <= 0) {
          timer.cancel();
          completeFocusTimer();
        } else {
          _timerState = _timerState.copyWith(remainingSeconds: remaining);
          _focusTimerController.add(_timerState);
        }
      });
    }
  }

  // 집중 타이머 중지
  @override
  Future<void> stopFocusTimer() async {
    _focusTimer?.cancel();

    _timerState = TimerState();
    _focusTimerController.add(_timerState);

    _timerStartTime = null;
    _timerPauseTime = null;
  }

  // 집중 타이머 완료
  @override
  Future<void> completeFocusTimer() async {
    try {
      _focusTimer?.cancel();

      // 타이머 완료 알림
      await _showTimerCompleteNotification();

      // 완료 사운드 재생 (소리 활성화된 경우에만)
      if (_enableSound) {
        await _playSound('timer_complete.mp3');
      }

      // 상태 업데이트
      if (_timerState.currentSession != null) {
        _timerState = TimerState(
          isRunning: false,
          isPaused: false,
          totalSeconds: _timerState.totalSeconds,
          remainingSeconds: 0,
          currentSession: _timerState.currentSession!.copyWith(
            isCompleted: true,
            endTime: DateTime.now(),
          ),
        );
      } else {
        // 세션이 없는 경우 기본 상태로 초기화
        _timerState = TimerState(
          isRunning: false,
          isPaused: false,
          totalSeconds: _timerState.totalSeconds,
          remainingSeconds: 0,
        );
      }

      _focusTimerController.add(_timerState);

      _timerStartTime = null;
      _timerPauseTime = null;
    } catch (e) {
      print('타이머 완료 처리 중 오류 발생: $e');
      // 오류가 발생해도 타이머 상태는 초기화
      _timerState = TimerState();
      _focusTimerController.add(_timerState);
    }
  }

  // 타이머 완료 알림 표시
  Future<void> _showTimerCompleteNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'focus_timer_channel',
        'Focus Timer Notifications',
        channelDescription: 'Notifications for focus timer completion',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0,
        '타이머 완료!',
        '집중 시간이 끝났습니다. 잘 하셨어요!',
        notificationDetails,
      );
    } catch (e) {
      print('알림 표시 오류: $e');
    }
  }

  // 사운드 재생 (소리 활성화된 경우에만)
  Future<void> _playSound(String soundName) async {
    if (!_enableSound) return; // 소리 비활성화 시 바로 리턴

    try {
      await _audioPlayer.play(AssetSource('sounds/$soundName'));
    } catch (e) {
      if (kDebugMode) {
        print('사운드 재생 오류: $e');
      }
    }
  }

  // 카운트다운 스트림
  @override
  Stream<int> get countdownStream => _countdownController.stream;

  // 집중 타이머 스트림
  @override
  Stream<TimerState> get focusTimerStream => _focusTimerController.stream;

  // 카운트다운 실행 중 여부
  @override
  bool get isCountdownRunning => _isCountdownRunning;

  // 집중 타이머 실행 중 여부
  @override
  bool get isFocusTimerRunning => _timerState.isRunning;

  // 집중 타이머 일시정지 여부
  @override
  bool get isFocusTimerPaused => _timerState.isPaused;

  // 리소스 해제
  void dispose() {
    _countdownTimer?.cancel();
    _focusTimer?.cancel();
    _countdownController.close();
    _focusTimerController.close();
    _audioPlayer.dispose();
  }
}
