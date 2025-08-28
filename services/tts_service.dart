import 'package:flutter_tts/flutter_tts.dart';
import 'package:launch/services/activity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsServiceImpl implements TtsService {
  // Flutter TTS 인스턴스
  final FlutterTts _flutterTts = FlutterTts();

  // TTS 활성화 상태 (기본값: 활성화)
  bool _isTtsEnabled = true;

  // SharedPreferences 키
  static const String _ttsEnabledKey = 'tts_enabled';

  /// 생성자
  TtsServiceImpl() {
    _initTts();
    _loadSettings();
  }

  /// TTS 초기화
  Future<void> _initTts() async {
    // 한국어 설정
    await _flutterTts.setLanguage('ko-KR');

    // 음성 속도 설정 (0.5: 느림, 1.0: 보통, 2.0: 빠름)
    await _flutterTts.setSpeechRate(0.5);

    // 음량 설정 (0.0 ~ 1.0)
    await _flutterTts.setVolume(1.0);

    // 음성 피치 설정 (1.0: 보통)
    await _flutterTts.setPitch(1.0);
  }

  /// 저장된 설정 불러오기
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTtsEnabled = prefs.getBool(_ttsEnabledKey) ?? true;
    } catch (e) {
      print('TTS 설정 로드 오류: $e');
      _isTtsEnabled = true; // 오류 시 기본값
    }
  }

  /// TTS 설정 저장
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ttsEnabledKey, _isTtsEnabled);
    } catch (e) {
      print('TTS 설정 저장 오류: $e');
    }
  }

  /// TTS 활성화 상태 반환
  @override
  bool get isTtsEnabled => _isTtsEnabled;

  /// TTS 활성화/비활성화 전환
  @override
  Future<void> toggleTts() async {
    _isTtsEnabled = !_isTtsEnabled;
    await _saveSettings();
  }

  /// TTS 활성화/비활성화 설정
  @override
  Future<void> setTtsEnabled(bool enabled) async {
    _isTtsEnabled = enabled;
    await _saveSettings();
  }

  /// 텍스트를 음성으로 변환
  @override
  Future<void> speak(String text) async {
    if (_isTtsEnabled) {
      await _flutterTts.speak(text);
    }
  }

  /// 현재 재생 중인 음성 중지
  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
