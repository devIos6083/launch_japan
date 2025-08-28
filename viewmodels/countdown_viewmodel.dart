import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:launch/services/activity_service.dart';

enum CountdownState {
  initial,
  counting,
  completed,
  canceled,
}

class CountdownViewModel with ChangeNotifier {
  final TimerService _timerService;
  final TtsService _ttsService; // TTS 서비스 추가

  CountdownState _state = CountdownState.initial;
  int _secondsRemaining = 10; // 기본값: 10초
  int _totalSeconds = 10;
  StreamSubscription<int>? _countdownSubscription;

  // 마지막으로 음성 안내한 숫자 (중복 방지용)
  int _lastSpokenNumber = -1;

  // 카운트다운 메시지 - 정확히 숫자에 맞춰서 설정
  final Map<int, String> _countdownMessages = {
    10: '10',
    9: '9',
    8: '8',
    7: '7',
    6: '6',
    5: '5',
    4: '4',
    3: '3',
    2: '2',
    1: '1',
    0: '시작!'
  };

  CountdownViewModel({
    required TimerService timerService,
    required TtsService ttsService, // TTS 서비스 추가
  })  : _timerService = timerService,
        _ttsService = ttsService {
    _initCountdownListener();
  }

  // 상태 및 데이터 접근자
  CountdownState get state => _state;
  int get secondsRemaining => _secondsRemaining;
  int get totalSeconds => _totalSeconds;
  bool get isTtsEnabled => _ttsService.isTtsEnabled;

  double get progress => _totalSeconds > 0
      ? ((_totalSeconds - _secondsRemaining) / _totalSeconds)
      : 0.0;
  bool get isRunning => _state == CountdownState.counting;

  // 카운트다운 리스너 초기화
  void _initCountdownListener() {
    _countdownSubscription = _timerService.countdownStream.listen((seconds) {
      _secondsRemaining = seconds;

      if (seconds <= 0) {
        _state = CountdownState.completed;
        // 0초일 때 "시작!" 메시지 재생
        if (_lastSpokenNumber != 0) {
          _speakCountdown(0);
          _lastSpokenNumber = 0;
        }
      } else {
        // 현재 초에 맞는 음성 안내
        if (_lastSpokenNumber != seconds) {
          _speakCountdown(seconds);
          _lastSpokenNumber = seconds;
        }
      }

      notifyListeners();
    });
  }

  // 카운트다운 상태 초기화 메서드 (에러 수정)
  void resetCountdown() {
    _state = CountdownState.initial;
    _secondsRemaining = _totalSeconds;
    _lastSpokenNumber = -1; // 초기화
    notifyListeners();
  }

  // 카운트다운 숫자 음성 재생
  void _speakCountdown(int seconds) {
    if (!_ttsService.isTtsEnabled) return; // TTS가 비활성화되어 있으면 무시

    if (_countdownMessages.containsKey(seconds)) {
      _ttsService.speak(_countdownMessages[seconds]!);
    }
  }

  // TTS 활성화/비활성화 전환
  Future<void> toggleTts() async {
    await _ttsService.toggleTts();
    notifyListeners();
  }

  // 카운트다운 시작
  Future<void> startCountdown({int seconds = 10}) async {
    if (_state == CountdownState.counting) {
      await cancelCountdown();
    }

    _totalSeconds = seconds;
    _secondsRemaining = seconds;
    _state = CountdownState.counting;
    _lastSpokenNumber = -1; // 초기화

    notifyListeners();

    await _timerService.startCountdown(seconds);
  }

  // 카운트다운 취소
  Future<void> cancelCountdown() async {
    if (_state == CountdownState.counting) {
      // TTS 중지
      await _ttsService.stop();

      await _timerService.cancelCountdown();
      _state = CountdownState.canceled;
      notifyListeners();
    }
  }

  // 카운트다운 완료 여부 확인
  bool isCompleted() {
    return _state == CountdownState.completed;
  }

  // 리소스 해제
  @override
  void dispose() {
    _countdownSubscription?.cancel();
    _ttsService.stop(); // TTS 중지
    super.dispose();
  }
}
