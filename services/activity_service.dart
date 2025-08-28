// lib/models/activity_model.dart
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// lib/services/activity_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:launch/services/activity_service.dart';
import 'package:uuid/uuid.dart';

class Activity {
  final String id;
  final String userId;
  final String activityId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final int durationSeconds;
  final int durationMinutes;
  final String name;
  final String emoji;
  final int completionCount;
  final String description; // description 필드 추가
  final DateTime createdAt; // 필요한 경우 추가
  final bool isCustom; // 필요한 경우 추가

  Activity({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.durationSeconds = 0,
    this.durationMinutes = 0,
    this.name = '',
    this.emoji = '❓',
    this.completionCount = 0,
    this.description = '', // 기본값 설정
    required this.createdAt, // 필요한 경우 추가
    this.isCustom = false, // 필요한 경우 추가
  });

  // 모델 데이터를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'durationSeconds': durationSeconds,
      'durationMinutes': durationMinutes,
      'name': name,
      'emoji': emoji,
      'completionCount': completionCount,
      'description': description, // JSON에 description 추가
      'createdAt': createdAt.toIso8601String(), // 필요한 경우 추가
      'isCustom': isCustom, // 필요한 경우 추가
    };
  }

  // JSON 데이터를 모델로 변환
  factory Activity.fromJson(Map<String, dynamic> json) {
    // DateTime 안전하게 파싱
    DateTime parseDateTime(dynamic value, {DateTime? defaultValue}) {
      final defaultTime = defaultValue ?? DateTime.now();

      if (value == null) return defaultTime;

      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('날짜 파싱 오류: $e, 기본값 사용');
          return defaultTime;
        }
      } else if (value is DateTime) {
        return value;
      }

      return defaultTime;
    }

    // int 안전하게 파싱
    int parseIntSafely(dynamic value, {int defaultValue = 0}) {
      if (value is int) return value;
      if (value == null) return defaultValue;

      try {
        return int.tryParse(value.toString()) ?? defaultValue;
      } catch (e) {
        return defaultValue;
      }
    }

    // bool 안전하게 파싱
    bool parseBoolSafely(dynamic value, {bool defaultValue = false}) {
      if (value is bool) return value;
      if (value == null) return defaultValue;

      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }

      if (value is num) {
        return value != 0;
      }

      return defaultValue;
    }

    // 필수 ID 확인
    String id = json['id']?.toString() ?? '';

    // 필수 userId 확인
    String userId = json['userId']?.toString() ?? '';
    if (userId.isEmpty) {
      print('경고: 세션에 userId가 없음, 기본값 사용');
      userId = 'unknown_user';
    }

    // 필수 activityId 확인
    String activityId = json['activityId']?.toString() ?? '';
    if (activityId.isEmpty) {
      print('경고: 세션에 activityId가 없음, 기본값 사용');
      activityId = 'unknown_activity';
    }

    // startTime은 필수, 없으면 현재 시간 사용
    DateTime startTime = parseDateTime(json['startTime']);

    // endTime은 선택, 없을 수 있음
    DateTime? endTime;
    if (json.containsKey('endTime') && json['endTime'] != null) {
      endTime = parseDateTime(json['endTime']);
    }

    // 완료 여부와 지속 시간 파싱
    bool isCompleted = parseBoolSafely(json['isCompleted']);
    int durationSeconds = parseIntSafely(json['durationSeconds']);
    int durationMinutes = parseIntSafely(json['durationMinutes']);

    // 새로 추가되는 필드들
    String name = json['name']?.toString() ?? '';
    String emoji = json['emoji']?.toString() ?? '❓';
    int completionCount = parseIntSafely(json['completionCount']);
    String description =
        json['description']?.toString() ?? ''; // description 파싱

    // createdAt 파싱
    DateTime createdAt = parseDateTime(json['createdAt']);

    // isCustom 파싱
    bool isCustom = parseBoolSafely(json['isCustom']);

    return Activity(
      id: id,
      userId: userId,
      activityId: activityId,
      startTime: startTime,
      endTime: endTime,
      isCompleted: isCompleted,
      durationSeconds: durationSeconds,
      durationMinutes: durationMinutes,
      name: name,
      emoji: emoji,
      completionCount: completionCount,
      description: description, // description 필드 추가
      createdAt: createdAt, // 필요한 경우 추가
      isCustom: isCustom, // 필요한 경우 추가
    );
  }

  // Firebase 데이터스냅샷에서 모델로 변환
  factory Activity.fromDatabase(DataSnapshot snapshot) {
    if (snapshot.value is! Map) {
      throw FormatException(
          '세션 데이터가 Map 형식이 아님: ${snapshot.value.runtimeType}');
    }

    // 안전하게 Map<String, dynamic>으로 변환
    final Map<String, dynamic> data = {};
    (snapshot.value as Map).forEach((key, value) {
      data[key.toString()] = value;
    });

    // ID 추가
    data['id'] = snapshot.key;

    return Activity.fromJson(data);
  }

  // 복사본 생성 (일부 속성 변경 가능)
  Activity copyWith({
    String? id,
    String? userId,
    String? activityId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    int? durationSeconds,
    int? durationMinutes,
    String? name,
    String? emoji,
    int? completionCount,
    String? description, // description 추가
    DateTime? createdAt, // 필요한 경우 추가
    bool? isCustom, // 필요한 경우 추가
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityId: activityId ?? this.activityId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      completionCount: completionCount ?? this.completionCount,
      description: description ?? this.description, // description 복사
      createdAt: createdAt ?? this.createdAt, // 필요한 경우 추가
      isCustom: isCustom ?? this.isCustom, // 필요한 경우 추가
    );
  }

  // 지속 시간 계산 (TimerService에서 사용된 부분 통합)
  Duration get duration {
    return Duration(
        seconds: durationSeconds > 0 ? durationSeconds : durationMinutes * 60);
  }

  // 기본 활동 목록 생성 - description 필드 추가
  static List<Activity> getDefaultActivities(String userId) {
    return [
      Activity(
        id: '', // 저장 시 자동 생성됨
        userId: userId,
        activityId: 'activity_1',
        startTime: DateTime.now(),
        durationMinutes: 25, // 포모도로 기본 시간
        name: '집중 활동',
        emoji: '🎯',
        description: '25분 동안 집중해서 작업하기', // description 추가
        createdAt: DateTime.now(), // 필요한 경우 추가
      ),
      Activity(
        id: '',
        userId: userId,
        activityId: 'activity_2',
        startTime: DateTime.now(),
        durationMinutes: 45,
        name: '중간 작업',
        emoji: '⏱️',
        description: '45분 타이머로 중간 규모 작업하기', // description 추가
        createdAt: DateTime.now(), // 필요한 경우 추가
      ),
      Activity(
        id: '',
        userId: userId,
        activityId: 'activity_3',
        startTime: DateTime.now(),
        durationMinutes: 60,
        name: '긴 작업',
        emoji: '📚',
        description: '1시간 동안 깊이 몰입하기', // description 추가
        createdAt: DateTime.now(), // 필요한 경우 추가
      ),
    ];
  }
}

// ActivitySession 클래스 추가 (ActivityRepository에서 참조됨)
class ActivitySession {
  final String id;
  final String userId;
  final String activityId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool completed;
  final Duration duration;

  ActivitySession({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.startTime,
    this.endTime,
    this.completed = false,
    required this.duration,
  });

  // 모델 데이터를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityId': activityId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'completed': completed,
      'durationSeconds': duration.inSeconds,
    };
  }

  // JSON 데이터를 모델로 변환
  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    // DateTime 안전하게 파싱
    DateTime parseDateTime(dynamic value, {DateTime? defaultValue}) {
      final defaultTime = defaultValue ?? DateTime.now();

      if (value == null) return defaultTime;

      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('날짜 파싱 오류: $e, 기본값 사용');
          return defaultTime;
        }
      } else if (value is DateTime) {
        return value;
      }

      return defaultTime;
    }

    // int 안전하게 파싱
    int parseIntSafely(dynamic value, {int defaultValue = 0}) {
      if (value is int) return value;
      if (value == null) return defaultValue;

      try {
        return int.tryParse(value.toString()) ?? defaultValue;
      } catch (e) {
        return defaultValue;
      }
    }

    // bool 안전하게 파싱
    bool parseBoolSafely(dynamic value, {bool defaultValue = false}) {
      if (value is bool) return value;
      if (value == null) return defaultValue;

      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }

      if (value is num) {
        return value != 0;
      }

      return defaultValue;
    }

    // 필수 ID 확인
    String id = json['id']?.toString() ?? '';

    // 필수 userId 확인
    String userId = json['userId']?.toString() ?? '';
    if (userId.isEmpty) {
      print('경고: 세션에 userId가 없음, 기본값 사용');
      userId = 'unknown_user';
    }

    // 필수 activityId 확인
    String activityId = json['activityId']?.toString() ?? '';
    if (activityId.isEmpty) {
      print('경고: 세션에 activityId가 없음, 기본값 사용');
      activityId = 'unknown_activity';
    }

    // startTime은 필수, 없으면 현재 시간 사용
    DateTime startTime = parseDateTime(json['startTime']);

    // endTime은 선택, 없을 수 있음
    DateTime? endTime;
    if (json.containsKey('endTime') && json['endTime'] != null) {
      endTime = parseDateTime(json['endTime']);
    }

    // 완료 여부와 지속 시간 파싱
    bool completed = parseBoolSafely(json['completed']);
    int durationSeconds = parseIntSafely(json['durationSeconds']);

    return ActivitySession(
      id: id,
      userId: userId,
      activityId: activityId,
      startTime: startTime,
      endTime: endTime,
      completed: completed,
      duration: Duration(seconds: durationSeconds),
    );
  }

  // Firebase 데이터스냅샷에서 모델로 변환
  factory ActivitySession.fromDatabase(DataSnapshot snapshot) {
    if (snapshot.value is! Map) {
      throw FormatException(
          '세션 데이터가 Map 형식이 아님: ${snapshot.value.runtimeType}');
    }

    // 안전하게 Map<String, dynamic>으로 변환
    final Map<String, dynamic> data = {};
    (snapshot.value as Map).forEach((key, value) {
      data[key.toString()] = value;
    });

    // ID 추가
    data['id'] = snapshot.key;

    return ActivitySession.fromJson(data);
  }

  // 복사본 생성 (일부 속성 변경 가능)
  ActivitySession copyWith({
    String? id,
    String? userId,
    String? activityId,
    DateTime? startTime,
    DateTime? endTime,
    bool? completed,
    Duration? duration,
  }) {
    return ActivitySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityId: activityId ?? this.activityId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completed: completed ?? this.completed,
      duration: duration ?? this.duration,
    );
  }
}

abstract class StorageService {
  Future<String?> getString(String key);
  Future<int?> getInt(String key);
  Future<double?> getDouble(String key);
  Future<bool?> getBool(String key);
  Future<List<String>?> getStringList(String key);
  Future<Map<String, dynamic>?> getObject(String key);

  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
  Future<void> setDouble(String key, double value);
  Future<void> setBool(String key, bool value);
  Future<void> setStringList(String key, List<String> value);
  Future<void> setObject(String key, Map<String, dynamic> value);

  Future<void> remove(String key);
  Future<void> clear();
}

class StorageServiceImpl implements StorageService {
  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  @override
  Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  @override
  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  @override
  Future<Map<String, dynamic>?> getObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    try {
      return Map<String, dynamic>.from(
        json.decode(jsonString) as Map,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  @override
  Future<void> setObject(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(value));
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

abstract class ActivityService {
  Future<List<Activity>> getUserActivities(String userId);
  Future<Activity> getActivity(String activityId);
  Future<Activity> createActivity(Activity activity);
  Future<void> updateActivity(Activity activity);
  Future<void> deleteActivity(String activityId);
  Future<void> incrementCompletionCount(String activityId);
  Future<List<ActivitySession>> getUserActivitySessions(String userId,
      {DateTime? startDate, DateTime? endDate});
  Future<ActivitySession> createActivitySession(ActivitySession session);
  Future<void> updateActivitySession(ActivitySession session);
  Future<void> completeActivitySession(String sessionId);
  Future<void> updateUserStatistics(
    String userId, {
    int completedActivities = 0,
    bool incrementStreak = false,
    String? dayOfWeek,
  });
  Stream<List<Activity>> userActivitiesStream(String userId);

  // 요일명 변환 헬퍼
  String getDayName(int weekday);
}

class FirebaseActivityService implements ActivityService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Firebase 경로
  static const String _activitiesPath = 'activities';
  static const String _sessionsPath = 'sessions';

  @override
  Future<List<Activity>> getUserActivities(String userId) async {
    if (userId.isEmpty) {
      print('경고: 빈 userId로 활동을 조회했습니다.');
      return [];
    }

    final activitiesRef = _database
        .ref()
        .child(_activitiesPath)
        .orderByChild('userId')
        .equalTo(userId);
    final snapshot = await activitiesRef.get();

    if (snapshot.exists && snapshot.value != null) {
      final List<Activity> activities = [];

      final Map<dynamic, dynamic> values = snapshot.value as Map;
      values.forEach((key, value) {
        try {
          // userId 확인 - 다른 사용자의 활동이 포함되지 않도록 추가 검증
          final Map<String, dynamic> activityData =
              Map<String, dynamic>.from(value as Map);
          if (activityData['userId'] == userId) {
            activityData['id'] = key;
            final activity = Activity.fromJson(activityData);
            activities.add(activity);
          }
        } catch (e) {
          print('활동 파싱 오류: $e');
        }
      });

      return activities;
    }

    return [];
  }

  @override
  Future<Activity> getActivity(String activityId) async {
    final activityRef = _database.ref().child('$_activitiesPath/$activityId');
    final snapshot = await activityRef.get();

    if (snapshot.exists && snapshot.value != null) {
      return Activity.fromDatabase(snapshot);
    }

    throw Exception('활동을 찾을 수 없음: $activityId');
  }

  @override
  Future<Activity> createActivity(Activity activity) async {
    final activityRef = _database.ref().child(_activitiesPath).push();
    final newActivity = activity.copyWith(id: activityRef.key);

    await activityRef.set(newActivity.toJson());
    return newActivity;
  }

  @override
  Future<void> updateActivity(Activity activity) async {
    final activityRef =
        _database.ref().child('$_activitiesPath/${activity.id}');
    await activityRef.update(activity.toJson());
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    final activityRef = _database.ref().child('$_activitiesPath/$activityId');
    await activityRef.remove();
  }

  @override
  Future<void> incrementCompletionCount(String activityId) async {
    final activityRef =
        _database.ref().child('$_activitiesPath/$activityId/completionCount');
    await activityRef.runTransaction((currentValue) {
      if (currentValue == null) {
        return Transaction.success(1);
      }

      return Transaction.success(((currentValue as int?) ?? 0) + 1);
    });
  }

  @override
  Future<List<ActivitySession>> getUserActivitySessions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query sessionsRef = _database
        .ref()
        .child(_sessionsPath)
        .orderByChild('userId')
        .equalTo(userId);

    if (startDate != null) {
      sessionsRef = sessionsRef
          .orderByChild('startTime')
          .startAt(startDate.toIso8601String());
    }

    if (endDate != null) {
      sessionsRef = sessionsRef
          .orderByChild('startTime')
          .endAt(endDate.toIso8601String());
    }

    final snapshot = await sessionsRef.get();

    if (snapshot.exists && snapshot.value != null) {
      final List<ActivitySession> sessions = [];

      final Map<dynamic, dynamic> values = snapshot.value as Map;
      values.forEach((key, value) {
        try {
          final session = ActivitySession.fromJson({
            ...Map<String, dynamic>.from(value as Map),
            'id': key,
          });
          sessions.add(session);
        } catch (e) {
          print('세션 파싱 오류: $e');
        }
      });

      return sessions;
    }

    return [];
  }

  @override
  Future<ActivitySession> createActivitySession(ActivitySession session) async {
    final sessionRef = _database.ref().child(_sessionsPath).push();
    final newSession = session.copyWith(id: sessionRef.key);

    await sessionRef.set(newSession.toJson());
    return newSession;
  }

  @override
  Future<void> updateActivitySession(ActivitySession session) async {
    final sessionRef = _database.ref().child('$_sessionsPath/${session.id}');
    await sessionRef.update(session.toJson());
  }

  @override
  Future<void> completeActivitySession(String sessionId) async {
    final sessionRef = _database.ref().child('$_sessionsPath/$sessionId');

    // 현재 세션 데이터 가져오기
    final snapshot = await sessionRef.get();
    if (!snapshot.exists) {
      throw Exception('세션을 찾을 수 없음: $sessionId');
    }

    // 이미 완료된 세션인지 확인
    try {
      final Map<dynamic, dynamic> sessionData = snapshot.value as Map;
      final bool isAlreadyCompleted = sessionData['completed'] == true;

      if (isAlreadyCompleted) {
        print('이미 완료된 세션입니다: $sessionId');
        return; // 이미 완료된 세션이면 처리 중단
      }
    } catch (e) {
      print('세션 데이터 확인 오류: $e');
    }

    // 세션 완료 처리
    await sessionRef.update({
      'completed': true,
      'endTime': DateTime.now().toIso8601String(),
    });

    // 해당 활동의 완료 카운트 증가
    try {
      final sessionData = ActivitySession.fromDatabase(snapshot);

      // 활동 완료 카운트 증가 - 이 부분을 별도 처리
      await incrementCompletionCount(sessionData.activityId);

      // 사용자 통계 업데이트
      final now = DateTime.now();
      final dayOfWeek = getDayName(now.weekday);
      await updateUserStatistics(
        sessionData.userId,
        completedActivities: 1,
        incrementStreak: true,
        dayOfWeek: dayOfWeek,
      );
    } catch (e) {
      print('통계 업데이트 오류: $e');
    }
  }

  // 이 메서드 구현이 없어서 추가
  @override
  Future<void> updateUserStatistics(
    String userId, {
    int completedActivities = 0,
    bool incrementStreak = false,
    String? dayOfWeek,
  }) async {
    // 여기에 사용자 통계 업데이트 로직을 구현해야 합니다
    // 이 구현은 FirebaseService 또는 UserService에 있을 것으로 예상됩니다
    print(
        '사용자 통계 업데이트 - userId: $userId, 완료활동: $completedActivities, 스트릭: $incrementStreak, 요일: $dayOfWeek');
    // 실제 로직 구현은 코드 구조에 따라 다를 수 있음
  }

  @override
  Stream<List<Activity>> userActivitiesStream(String userId) {
    if (userId.isEmpty) {
      print('경고: 빈 userId로 활동 스트림을 구독했습니다.');
      return Stream.value([]);
    }

    final activitiesRef = _database
        .ref()
        .child(_activitiesPath)
        .orderByChild('userId')
        .equalTo(userId);

    return activitiesRef.onValue.map((event) {
      final snapshot = event.snapshot;

      if (snapshot.exists && snapshot.value != null) {
        final List<Activity> activities = [];

        final Map<dynamic, dynamic> values = snapshot.value as Map;
        values.forEach((key, value) {
          try {
            // userId 확인 - 추가 검증
            final Map<String, dynamic> activityData =
                Map<String, dynamic>.from(value as Map);
            if (activityData['userId'] == userId) {
              activityData['id'] = key;
              final activity = Activity.fromJson(activityData);
              activities.add(activity);
            }
          } catch (e) {
            print('활동 스트림 파싱 오류: $e');
          }
        });

        // 생성 시간 기준 정렬 (최신순)
        activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return activities;
      }

      return <Activity>[];
    });
  }

  // 요일명 반환 헬퍼 메서드
  @override
  String getDayName(int weekday) {
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

abstract class ActivityRepository {
  // ActivityRepository 메서드
  Future<List<Activity>> getUserActivities(String userId);
  Future<Activity> getActivity(String activityId);
  Future<Activity> createActivity(Activity activity);
  Future<void> updateActivity(Activity activity);
  Future<void> deleteActivity(String activityId);
  Future<void> incrementCompletionCount(String activityId);
  Future<List<ActivitySession>> getUserActivitySessions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<ActivitySession> createActivitySession(ActivitySession session);
  Future<void> updateActivitySession(ActivitySession session);
  Future<void> completeActivitySession(String sessionId);
  Future<bool> hasDefaultActivities(String userId);
  Future<void> createDefaultActivities(String userId);
  Stream<List<Activity>> userActivitiesStream(String userId);
}

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityService _activityService;
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  // 저장소 키
  static const String _keyHasDefaultActivities = 'has_default_activities_';

  ActivityRepositoryImpl({
    required ActivityService activityService,
    required StorageService storageService,
  })  : _activityService = activityService,
        _storageService = storageService;

  @override
  Future<List<Activity>> getUserActivities(String userId) {
    return _activityService.getUserActivities(userId);
  }

  @override
  Future<Activity> getActivity(String activityId) {
    return _activityService.getActivity(activityId);
  }

  @override
  Future<Activity> createActivity(Activity activity) {
    // ID가 없으면 UUID 생성
    final newActivity =
        activity.id.isEmpty ? activity.copyWith(id: _uuid.v4()) : activity;

    // 항상 userId 확인 - 사용자별 활동 관리를 위해 중요
    if (newActivity.userId.isEmpty) {
      print('경고: 빈 userId로 활동을 생성했습니다. 이 활동은 조회되지 않을 수 있습니다.');
    }

    return _activityService.createActivity(newActivity);
  }

  @override
  Future<void> updateActivity(Activity activity) {
    return _activityService.updateActivity(activity);
  }

  @override
  Future<void> deleteActivity(String activityId) {
    return _activityService.deleteActivity(activityId);
  }

  @override
  Future<void> incrementCompletionCount(String activityId) {
    return _activityService.incrementCompletionCount(activityId);
  }

  @override
  Future<List<ActivitySession>> getUserActivitySessions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _activityService.getUserActivitySessions(userId,
        startDate: startDate, endDate: endDate);
  }

  @override
  Future<ActivitySession> createActivitySession(ActivitySession session) {
    // ID가 없으면 UUID 생성
    final String sessionId = _uuid.v4();
    final newSession = session.copyWith(id: sessionId);
    print('저장소에서 세션 생성 요청: ${newSession.id}');
    return _activityService.createActivitySession(newSession);
  }

  @override
  Future<void> updateActivitySession(ActivitySession session) {
    return _activityService.updateActivitySession(session);
  }

  @override
  Future<void> completeActivitySession(String sessionId) {
    // 세션 ID 검증
    if (sessionId.isEmpty || sessionId == 'temp_id') {
      print('유효하지 않은 세션 ID: $sessionId - 세션 완료를 건너뜁니다');
      return Future.value(); // 예외를 발생시키지 않고 조용히 반환
    }

    return _activityService.completeActivitySession(sessionId);
  }

  @override
  Future<bool> hasDefaultActivities(String userId) async {
    final key = '$_keyHasDefaultActivities$userId';
    return await _storageService.getBool(key) ?? false;
  }

  @override
  Future<void> createDefaultActivities(String userId) async {
    // 이미 존재하는 활동이 있는지 확인
    final activities = await _activityService.getUserActivities(userId);
    if (activities.isNotEmpty) {
      // 이미 활동이 있다면 기본 활동을 생성하지 않음
      final key = '$_keyHasDefaultActivities$userId';
      await _storageService.setBool(key, true);
      print('$userId 사용자에게 이미 활동이 있어 기본 활동을 생성하지 않습니다.');
      return;
    }

    // 기본 활동 목록 가져오기
    final defaultActivities = Activity.getDefaultActivities(userId);

    // 기본 활동 저장
    for (final activity in defaultActivities) {
      // userId 재확인 - 다른 사용자 활동이 보이는 문제 방지
      final activityWithCorrectUserId = activity.copyWith(userId: userId);
      await _activityService.createActivity(activityWithCorrectUserId);
    }

    // 기본 활동 생성 완료 표시
    final key = '$_keyHasDefaultActivities$userId';
    await _storageService.setBool(key, true);
    print('$userId 사용자를 위한 기본 활동 ${defaultActivities.length}개가 생성되었습니다.');
  }

  @override
  Stream<List<Activity>> userActivitiesStream(String userId) {
    return _activityService.userActivitiesStream(userId);
  }
}

class TimerState {
  final bool isRunning;
  final bool isPaused;
  final int totalSeconds;
  final int remainingSeconds;
  final Activity? currentSession;

  TimerState({
    this.isRunning = false,
    this.isPaused = false,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.currentSession,
  });

  TimerState copyWith({
    bool? isRunning,
    bool? isPaused,
    int? totalSeconds,
    int? remainingSeconds,
    Activity? currentSession,
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      currentSession: currentSession ?? this.currentSession,
    );
  }
}

abstract class TimerService {
  // 카운트다운 관련
  Future<void> startCountdown(int seconds);
  Future<void> cancelCountdown();
  Stream<int> get countdownStream;

  // 집중 타이머 관련
  Future<void> startFocusTimer(Activity activity);
  Future<void> pauseFocusTimer();
  Future<void> resumeFocusTimer();
  Future<void> stopFocusTimer();
  Future<void> completeFocusTimer();
  Stream<TimerState> get focusTimerStream;

  // 상태 확인
  bool get isCountdownRunning;
  bool get isFocusTimerRunning;
  bool get isFocusTimerPaused;

  // 알림 설정
  Future<void> setupNotifications();
}

/// TTS(Text-to-Speech) 서비스 인터페이스
abstract class TtsService {
  /// TTS 활성화 상태
  bool get isTtsEnabled;

  /// TTS 활성화/비활성화 전환
  Future<void> toggleTts();

  /// TTS 활성화/비활성화 설정
  Future<void> setTtsEnabled(bool enabled);

  /// 텍스트를 음성으로 변환
  Future<void> speak(String text);

  /// 현재 재생 중인 음성 중지
  Future<void> stop();
}
