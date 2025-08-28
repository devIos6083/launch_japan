// lib/models/user_model.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:launch/services/activity_service.dart';
import 'package:launch/services/storage_service.dart';
import 'package:launch/services/timer_service.dart';
import 'package:launch/services/tts_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

enum LoginProvider {
  email,
  google,
  kakao,
}

/// ⚠️ 중요: Realtime Database 전용 UserService
class UserService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  static const String _usersPath = 'users';

  /// 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final snap = await _db.ref('$_usersPath/$userId').get();
    if (!snap.exists) return null;

    // Map<String,dynamic> 안전 변환
    final Map<String, dynamic> data = {};
    if (snap.value is Map) {
      (snap.value as Map).forEach((k, v) => data[k.toString()] = v);
    }

    // ⚠️ 중요: weeklyProgress 항상 정상화
    data['weeklyProgress'] = _normalizeWeeklyProgress(data['weeklyProgress']);
    return data;
  }

  /// 프로필 부분 업데이트
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    if (updates.containsKey('weeklyProgress')) {
      updates['weeklyProgress'] =
          _normalizeWeeklyProgress(updates['weeklyProgress']);
    }
    await _db.ref('$_usersPath/$userId').update(updates);
  }

  /// 주간 진행상황 안전 보정
  Map<String, int> _normalizeWeeklyProgress(dynamic source) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final Map<String, int> safe = {for (var d in days) d: 0};

    if (source is Map) {
      source.forEach((k, v) {
        safe[k.toString()] = v is int
            ? v
            : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
      });
    }
    return safe;
  }
}

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final LoginProvider loginProvider;
  final List<String> favoriteActivityIds;
  final int streak; // 연속 사용 일수
  final int totalCompletedActivities;
  final Map<String, int> weeklyProgress; // 요일별 완료 활동 수
  final String? lastActivityDate;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    required this.loginProvider,
    this.favoriteActivityIds = const [],
    this.streak = 0,
    this.totalCompletedActivities = 0,
    this.lastActivityDate,
    Map<String, int>? weeklyProgress,
  }) : weeklyProgress = weeklyProgress ??
            {
              'monday': 0,
              'tuesday': 0,
              'wednesday': 0,
              'thursday': 0,
              'friday': 0,
              'saturday': 0,
              'sunday': 0,
            };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Realtime Database에서는 DateTime이 String으로 저장됨
    DateTime parseDateTime(dynamic value) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('DateTime 파싱 오류: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // 리스트 변환 처리 (Realtime Database에서는 리스트가 Map으로 저장될 수 있음)
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is Map) return value.values.map((e) => e.toString()).toList();
      return [];
    }

    // Map 변환 처리 개선
    Map<String, int> parseWeeklyProgress(dynamic value) {
      // 기본값 맵 생성
      final Map<String, int> defaultMap = {
        'monday': 0,
        'tuesday': 0,
        'wednesday': 0,
        'thursday': 0,
        'friday': 0,
        'saturday': 0,
        'sunday': 0,
      };

      if (value == null) {
        return defaultMap;
      }

      try {
        if (value is Map) {
          // 안전하게 타입 변환
          final Map<String, int> result = {};

          value.forEach((key, val) {
            if (key is String || key != null) {
              final String safeKey = key.toString();
              int safeValue = 0;

              if (val is int) {
                safeValue = val;
              } else if (val is num) {
                safeValue = val.toInt();
              } else if (val != null) {
                try {
                  safeValue = int.tryParse(val.toString()) ?? 0;
                } catch (e) {
                  print('Int 파싱 오류: $e');
                }
              }

              result[safeKey] = safeValue;
            }
          });

          // 모든 요일에 대한 기본값 확인
          defaultMap.forEach((key, value) {
            if (!result.containsKey(key)) {
              result[key] = value;
            }
          });

          return result;
        }
      } catch (e) {
        print('Weekly progress 파싱 오류: $e');
      }

      return defaultMap;
    }

    try {
      return UserProfile(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        displayName: json['displayName']?.toString(),
        photoUrl: json['photoUrl']?.toString(),
        createdAt: parseDateTime(json['createdAt']),
        lastLoginAt: parseDateTime(json['lastLoginAt']),
        loginProvider: _parseLoginProvider(json['loginProvider']),
        favoriteActivityIds: parseStringList(json['favoriteActivityIds']),
        streak: _parseIntSafely(json['streak']),
        totalCompletedActivities:
            _parseIntSafely(json['totalCompletedActivities']),
        weeklyProgress: parseWeeklyProgress(json['weeklyProgress']),
        lastActivityDate: json['lastActivityDate']?.toString(),
      );
    } catch (e) {
      print('UserProfile fromJson 오류: $e');
      // 기본값으로 객체 생성
      return UserProfile(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        loginProvider: LoginProvider.email,
      );
    }
  }

  // 정수를 안전하게 파싱하는 헬퍼 메서드
  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    try {
      return int.tryParse(value.toString()) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // LoginProvider를 안전하게 파싱하는 헬퍼 메서드
  static LoginProvider _parseLoginProvider(dynamic value) {
    if (value == null) return LoginProvider.email;

    if (value is String) {
      try {
        return LoginProvider.values.byName(value);
      } catch (e) {
        return LoginProvider.email;
      }
    }

    return LoginProvider.email;
  }

  factory UserProfile.fromDatabase(DataSnapshot snapshot) {
    try {
      Map<String, dynamic> data;

      if (snapshot.value is Map) {
        // 안전하게 Map<String, dynamic>으로 변환
        data = {};
        (snapshot.value as Map).forEach((key, value) {
          if (key != null) {
            data[key.toString()] = value;
          }
        });
      } else {
        data = {};
      }

      data['id'] = snapshot.key;
      return UserProfile.fromJson(data);
    } catch (e) {
      print('UserProfile fromDatabase 오류: $e');
      // 기본값으로 객체 생성
      return UserProfile(
        id: snapshot.key ?? '',
        email: '',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        loginProvider: LoginProvider.email,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(), // DateTime을 String으로 변환
      'lastLoginAt': lastLoginAt.toIso8601String(), // DateTime을 String으로 변환
      'loginProvider': loginProvider.name,
      'favoriteActivityIds': favoriteActivityIds,
      'streak': streak,
      'totalCompletedActivities': totalCompletedActivities,
      'weeklyProgress': weeklyProgress,
      'lastActivityDate': lastActivityDate,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    LoginProvider? loginProvider,
    List<String>? favoriteActivityIds,
    int? streak,
    int? totalCompletedActivities,
    Map<String, int>? weeklyProgress,
    String? lastActivityDate,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      loginProvider: loginProvider ?? this.loginProvider,
      favoriteActivityIds: favoriteActivityIds ?? this.favoriteActivityIds,
      streak: streak ?? this.streak,
      totalCompletedActivities:
          totalCompletedActivities ?? this.totalCompletedActivities,
      weeklyProgress:
          weeklyProgress ?? Map<String, int>.from(this.weeklyProgress),
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  // 요일별 진행 상황 업데이트
  UserProfile updateDailyProgress() {
    final today = DateTime.now();
    String dayName = _getDayName(today.weekday);

    final newProgress = Map<String, int>.from(weeklyProgress);
    newProgress[dayName] = (newProgress[dayName] ?? 0) + 1;

    return copyWith(
      weeklyProgress: newProgress,
      totalCompletedActivities: totalCompletedActivities + 1,
    );
  }

  // 스트릭 업데이트 (연속 사용 일수)
  UserProfile updateStreak(DateTime lastActiveDate) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    // 어제 활동했는지 확인
    final bool wasActiveYesterday = lastActiveDate.year == yesterday.year &&
        lastActiveDate.month == yesterday.month &&
        lastActiveDate.day == yesterday.day;

    // 오늘 활동했는지 확인
    final bool isActiveToday = lastActiveDate.year == now.year &&
        lastActiveDate.month == now.month &&
        lastActiveDate.day == now.day;

    // 어제 활동했으면 스트릭 유지/증가, 아니면 리셋
    if (wasActiveYesterday || isActiveToday) {
      return copyWith(streak: streak + 1);
    } else {
      return copyWith(streak: 1); // 스트릭 리셋
    }
  }

  // 요일명 반환
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

/// 통합된 Firebase 서비스 인터페이스
/// Activity와 User 관련 기능을 포함합니다.
abstract class FirebaseService {
  // Activity 관련 메서드
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
  Stream<List<Activity>> userActivitiesStream(String userId);

  // User 관련 메서드
  Future<UserProfile?> getUserProfile(String userId);
  Future<UserProfile> createUserProfile(UserProfile profile);
  Future<void> updateUserProfile(UserProfile profile);

  // 수정된 updateUserStatistics 메서드 - 매개변수 선언 일치시키기
  Future<void> updateUserStatistics(
    String userId, {
    int completedActivities = 0, // 기본값을 0으로 설정
    bool incrementStreak = false, // 기본값을 false로 설정
    String? dayOfWeek,
  });

  Stream<UserProfile?> userProfileStream(String userId);
  Stream<List<ActivitySession>> activitySessionsStream(String userId);
}

/// 통합된 Firebase 서비스 구현 클래스
class FirebaseServiceImpl implements FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  // ⚠️ 중요: 새 UserService 주입
  final UserService _userService = UserService();

  // Firebase 경로 상수
  static const String _activitiesPath = 'activities';
  static const String _sessionsPath = 'sessions';
  static const String _usersPath = 'users';

  //
  // Activity 관련 구현
  //

  @override
  Future<List<Activity>> getUserActivities(String userId) async {
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
        final activity = Activity.fromJson({
          ...Map<String, dynamic>.from(value as Map),
          'id': key,
        });
        activities.add(activity);
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

      return Transaction.success((currentValue as int? ?? 0) + 1);
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

    // 세션 완료 처리
    await sessionRef.update({
      'completed': true,
      'endTime': DateTime.now().toIso8601String(),
    });

    // 해당 활동의 완료 카운트 증가
    try {
      final sessionData = ActivitySession.fromDatabase(snapshot);
      await incrementCompletionCount(sessionData.activityId);

      // 사용자 통계도 업데이트
      final now = DateTime.now();
      final dayOfWeek = _getDayName(now.weekday);
      await updateUserStatistics(
        sessionData.userId,
        completedActivities: 1,
        incrementStreak: true,
        dayOfWeek: dayOfWeek,
      );
    } catch (e) {
      print('완료 카운트 및 사용자 통계 업데이트 오류: $e');
    }
  }

  @override
  Stream<List<Activity>> userActivitiesStream(String userId) {
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
            final activity = Activity.fromJson({
              ...Map<String, dynamic>.from(value as Map),
              'id': key,
            });
            activities.add(activity);
          } catch (e) {
            print('활동 스트림 파싱 오류: $e');
          }
        });

        return activities;
      }

      return <Activity>[];
    });
  }

  //
  // User 관련 구현
  //
  @override
  Future<void> updateUserStatistics(
    String userId, {
    int completedActivities = 0,
    bool incrementStreak = false,
    String? dayOfWeek,
  }) async {
    try {
      // 현재 사용자 프로필 가져오기
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) {
        // 사용자 프로필이 없으면 생성
        print('사용자 프로필을 찾을 수 없음, 새로 생성합니다');

        // 오늘 날짜
        final today = DateTime.now();
        final todayString =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        // 기본 프로필 데이터
        final newProfile = UserProfile(
          id: userId,
          email: 'temp@example.com', // 임시 이메일 (나중에 업데이트 예정)
          createdAt: today,
          lastLoginAt: today,
          loginProvider: LoginProvider.email,
          streak: 0,
          totalCompletedActivities: 0,
          lastActivityDate: todayString,
        );

        await createUserProfile(newProfile);

        // 새로 생성된 프로필을 다시 가져옴
        final freshProfile = await getUserProfile(userId);
        if (freshProfile == null) {
          throw Exception('프로필 생성 후에도 프로필을 찾을 수 없음');
        }

        // 업데이트할 데이터 준비
        final Map<String, dynamic> updates = {};

        // 완료된 활동 수 설정
        if (completedActivities > 0) {
          updates['totalCompletedActivities'] = completedActivities;
        }

        // streak 설정
        if (incrementStreak) {
          updates['streak'] = 1; // 처음이므로 1로 설정
        }

        // 요일별 진행 상황 업데이트
        if (dayOfWeek != null) {
          final Map<String, dynamic> safeWeeklyProgress = {
            'monday': 0,
            'tuesday': 0,
            'wednesday': 0,
            'thursday': 0,
            'friday': 0,
            'saturday': 0,
            'sunday': 0,
          };

          // 오늘 요일 카운트 증가
          safeWeeklyProgress[dayOfWeek] = 1;

          // 업데이트 데이터에 추가
          updates['weeklyProgress'] = safeWeeklyProgress;
        }

        // 업데이트할 내용이 있으면 저장
        if (updates.isNotEmpty) {
          await _userService.updateUserProfile(userId, updates);
          print('새 사용자 통계 설정 성공: $updates');
        }

        return; // 새 프로필 업데이트 완료
      }

      // 기존 프로필이 있는 경우 업데이트
      // 업데이트할 데이터 준비
      final updates = <String, dynamic>{};

      // 완료된 활동 수 증가
      if (completedActivities > 0) {
        final newTotal =
            userProfile.totalCompletedActivities + completedActivities;
        updates['totalCompletedActivities'] = newTotal;
        print('총 활동 수 업데이트: $newTotal');
      }

      // 연속 일수 증가
      if (incrementStreak) {
        // 오늘 날짜
        final today = DateTime.now();
        final todayString =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        int newStreak = userProfile.streak;

        // 마지막 활동 날짜와 비교
        if (userProfile.lastActivityDate != todayString) {
          // 어제 활동했는지 확인
          final yesterday = today.subtract(const Duration(days: 1));
          final yesterdayString =
              '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

          if (userProfile.lastActivityDate == yesterdayString) {
            // 어제 활동했으면 streak 증가
            newStreak = userProfile.streak + 1;
            print('연속 일수 증가: $newStreak');
          } else {
            // 어제 활동하지 않았으면 streak 초기화
            newStreak = 1;
            print('연속 일수 초기화: 1');
          }

          // 마지막 활동 날짜 업데이트
          updates['lastActivityDate'] = todayString;
        }

        updates['streak'] = newStreak;
      }

      // 요일별 진행 상황 업데이트
      if (dayOfWeek != null) {
        try {
          // 기존 weeklyProgress를 안전하게 가져와서 작업
          Map<String, dynamic> safeWeeklyProgress = {};

          // 1. 기존 값 복사
          userProfile.weeklyProgress.forEach((key, value) {
            safeWeeklyProgress[key] =
                value is int ? value : (value is num ? value.toInt() : 0);
          });

          // 2. 기본값 확인
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

          // 3. 현재 요일 증가
          int currentValue = (safeWeeklyProgress[dayOfWeek] is int)
              ? safeWeeklyProgress[dayOfWeek] as int
              : ((safeWeeklyProgress[dayOfWeek] is num)
                  ? (safeWeeklyProgress[dayOfWeek] as num).toInt()
                  : 0);

          safeWeeklyProgress[dayOfWeek] = currentValue + 1;

          updates['weeklyProgress'] = safeWeeklyProgress;
          print('요일별 진행 상황 업데이트: $safeWeeklyProgress');
        } catch (e) {
          print('주간 진행 상황 처리 오류: $e');

          // 오류 발생 시 새로운 맵으로 대체
          final Map<String, dynamic> defaultWeeklyProgress = {
            'monday': 0,
            'tuesday': 0,
            'wednesday': 0,
            'thursday': 0,
            'friday': 0,
            'saturday': 0,
            'sunday': 0,
          };

          defaultWeeklyProgress[dayOfWeek] = 1;
          updates['weeklyProgress'] = defaultWeeklyProgress;
          print('기본 주간 진행 상황으로 대체: $defaultWeeklyProgress');
        }
      }

      // 업데이트할 내용이 있으면 저장
      if (updates.isNotEmpty) {
        try {
          await _userService.updateUserProfile(userId, updates);
          print('사용자 통계 업데이트 성공: $updates');
        } catch (e) {
          print('사용자 프로필 업데이트 오류: $e');
          throw Exception('사용자 프로필 업데이트 실패: $e');
        }
      } else {
        print('업데이트할 내용이 없습니다');
      }
    } catch (e) {
      print('사용자 통계 업데이트 오류: $e');
      rethrow; // 상위 호출자에게 에러 전파
    }
  }

  // 2. getUserProfile 메서드 수정 (weeklyProgress 처리 강화)
  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final profileData = await _userService.getUserProfile(userId);
      if (profileData == null) return null;

      // weeklyProgress가 null이거나 올바른 형식이 아닌 경우 기본값 설정
      if (profileData['weeklyProgress'] == null ||
          profileData['weeklyProgress'] is! Map<String, dynamic>) {
        profileData['weeklyProgress'] = {
          'monday': 0,
          'tuesday': 0,
          'wednesday': 0,
          'thursday': 0,
          'friday': 0,
          'saturday': 0,
          'sunday': 0,
        };
      }

      return UserProfile.fromJson(profileData);
    } catch (e) {
      print('사용자 프로필 가져오기 오류: $e');
      rethrow;
    }
  }

  @override
  Future<UserProfile> createUserProfile(UserProfile profile) async {
    try {
      // JSON 변환 시 DateTime을 문자열로 변환
      final Map<String, dynamic> profileData = profile.toJson();

      // id 필드는 데이터베이스 키로 사용되므로 제외
      profileData.remove('id');

      // 데이터 저장
      await _database.ref().child('$_usersPath/${profile.id}').set(profileData);

      return profile;
    } catch (e) {
      print('사용자 프로필 생성 오류: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      // JSON 변환 시 DateTime을 문자열로 변환
      final Map<String, dynamic> profileData = profile.toJson();

      // id 필드는 제외
      profileData.remove('id');

      await _database
          .ref()
          .child('$_usersPath/${profile.id}')
          .update(profileData);
    } catch (e) {
      print('사용자 프로필 업데이트 오류: $e');
      rethrow;
    }
  }

  @override
  Stream<UserProfile?> userProfileStream(String userId) {
    final reference = _database.ref().child('$_usersPath/$userId');

    return reference.onValue.map((event) {
      final snapshot = event.snapshot;

      if (snapshot.exists) {
        // 데이터베이스에서 프로필 변환
        return UserProfile.fromDatabase(snapshot);
      } else {
        return null;
      }
    });
  }

  @override
  Stream<List<ActivitySession>> activitySessionsStream(String userId) {
    final reference = _database.ref().child(_sessionsPath);

    return reference
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;

      if (snapshot.exists) {
        final Map<dynamic, dynamic>? sessions =
            snapshot.value as Map<dynamic, dynamic>?;
        if (sessions != null) {
          final List<ActivitySession> result = [];

          for (final entry in sessions.entries) {
            final data = Map<String, dynamic>.from(entry.value as Map);
            data['id'] = entry.key;

            // 날짜 변환 처리
            if (data['startTime'] is String) {
              data['startTime'] = DateTime.parse(data['startTime']);
            }
            if (data['endTime'] != null && data['endTime'] is String) {
              data['endTime'] = DateTime.parse(data['endTime']);
            }

            result.add(ActivitySession.fromJson(data));
          }

          // 시작 시간 기준 내림차순 정렬
          result.sort((a, b) => b.startTime.compareTo(a.startTime));

          return result;
        }
      }

      return <ActivitySession>[];
    });
  }

  // 요일명 반환 (UserProfile의 메서드와 동일, 여기서는 인스턴스를 생성하지 않고 사용하기 위해 추가)
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

/// 통합된 Firebase 저장소 인터페이스
/// 통합된 Firebase 저장소 인터페이스
abstract class FirebaseRepository {
  // Activity 관련 메서드
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
  Future<bool> hasDefaultActivities(String userId);
  Future<void> createDefaultActivities(String userId);
  Stream<List<Activity>> userActivitiesStream(String userId);

  // User 관련 메서드
  Future<UserProfile?> getUserProfile(String userId);
  Future<UserProfile> createUserProfile(String userId);
  Future<void> updateUserProfile(UserProfile profile);

  // 수정된 updateUserStatistics 메서드 - 매개변수 선언 일치시키기
  Future<void> updateUserStatistics(
    String userId, {
    int completedActivities = 0,
    bool incrementStreak = false,
    String? dayOfWeek,
  });

  Stream<UserProfile?> userProfileStream(String userId);
  Stream<List<ActivitySession>> activitySessionsStream(String userId);
}

/// 통합된 Firebase 저장소 구현 클래스
class FirebaseRepositoryImpl implements FirebaseRepository {
  final FirebaseService _firebaseService;
  final SharedPrefsStorageService _storageService;
  final Uuid _uuid = const Uuid();

  // 저장소 키
  static const String _keyHasDefaultActivities = 'has_default_activities_';

  FirebaseRepositoryImpl({
    required FirebaseService firebaseService,
    required SharedPrefsStorageService storageService,
  })  : _firebaseService = firebaseService,
        _storageService = storageService;

  //
  // Activity 관련 구현
  //

  @override
  Future<List<Activity>> getUserActivities(String userId) {
    return _firebaseService.getUserActivities(userId);
  }

  @override
  Future<Activity> getActivity(String activityId) {
    return _firebaseService.getActivity(activityId);
  }

  @override
  Future<Activity> createActivity(Activity activity) {
    // ID가 없으면 UUID 생성
    final newActivity =
        activity.id.isEmpty ? activity.copyWith(id: _uuid.v4()) : activity;

    return _firebaseService.createActivity(newActivity);
  }

  @override
  Future<void> updateActivity(Activity activity) {
    return _firebaseService.updateActivity(activity);
  }

  @override
  Future<void> deleteActivity(String activityId) {
    return _firebaseService.deleteActivity(activityId);
  }

  @override
  Future<void> incrementCompletionCount(String activityId) {
    return _firebaseService.incrementCompletionCount(activityId);
  }

  @override
  Future<List<ActivitySession>> getUserActivitySessions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _firebaseService.getUserActivitySessions(userId,
        startDate: startDate, endDate: endDate);
  }

  @override
  Future<ActivitySession> createActivitySession(ActivitySession session) {
    // ID가 없으면 UUID 생성
    final String sessionId = _uuid.v4();
    final newSession = session.copyWith(id: sessionId);
    print('저장소에서 세션 생성 요청: ${newSession.id}');
    return _firebaseService.createActivitySession(newSession);
  }

  @override
  Future<void> updateActivitySession(ActivitySession session) {
    return _firebaseService.updateActivitySession(session);
  }

  @override
  Future<void> completeActivitySession(String sessionId) {
    // 세션 ID 검증
    if (sessionId.isEmpty || sessionId == 'temp_id') {
      print('유효하지 않은 세션 ID: $sessionId - 세션 완료를 건너뜁니다');
      return Future.value(); // 예외를 발생시키지 않고 조용히 반환
    }

    return _firebaseService.completeActivitySession(sessionId);
  }

  @override
  Future<bool> hasDefaultActivities(String userId) async {
    final key = '$_keyHasDefaultActivities$userId';
    return await _storageService.getBool(key) ?? false;
  }

  @override
  Future<void> createDefaultActivities(String userId) async {
    // 기본 활동 목록 가져오기
    final defaultActivities = Activity.getDefaultActivities(userId);

    // 기본 활동 저장
    for (final activity in defaultActivities) {
      await _firebaseService.createActivity(activity);
    }

    // 기본 활동 생성 완료 표시
    final key = '$_keyHasDefaultActivities$userId';
    await _storageService.setBool(key, true);
  }

  @override
  Stream<List<Activity>> userActivitiesStream(String userId) {
    return _firebaseService.userActivitiesStream(userId);
  }

  //
  // User 관련 구현
  //

  @override
  Future<UserProfile?> getUserProfile(String userId) {
    return _firebaseService.getUserProfile(userId);
  }

  @override
  Future<UserProfile> createUserProfile(String userId) {
    // 현재 날짜로 신규 사용자 프로필 생성
    final now = DateTime.now();
    final profile = UserProfile(
      id: userId,
      email: '', // 이 필드는 나중에 설정될 것으로 가정
      createdAt: now,
      lastLoginAt: now,
      loginProvider: LoginProvider.email, // 기본 로그인 제공자
      totalCompletedActivities: 0,
      streak: 0,
      weeklyProgress: {
        'monday': 0,
        'tuesday': 0,
        'wednesday': 0,
        'thursday': 0,
        'friday': 0,
        'saturday': 0,
        'sunday': 0,
      },
    );

    return _firebaseService.createUserProfile(profile);
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) {
    return _firebaseService.updateUserProfile(profile);
  }

  @override
  Future<void> updateUserStatistics(
    String userId, {
    int completedActivities = 0,
    bool incrementStreak = false,
    String? dayOfWeek,
  }) {
    return _firebaseService.updateUserStatistics(
      userId,
      completedActivities: completedActivities,
      incrementStreak: incrementStreak,
      dayOfWeek: dayOfWeek,
    );
  }

  @override
  Stream<UserProfile?> userProfileStream(String userId) {
    return _firebaseService.userProfileStream(userId);
  }

  @override
  Stream<List<ActivitySession>> activitySessionsStream(String userId) {
    return _firebaseService.activitySessionsStream(userId);
  }
}
// lib/models/user_model.dart의 마지막 부분을 다음과 같이 수정

/// 앱의 서비스 제공자 구성
/// 이 클래스의 이름을 변경하여 충돌을 방지합니다.
class UserServiceProviders extends StatelessWidget {
  final Widget child;

  const UserServiceProviders({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 서비스 레이어
        Provider<SharedPrefsStorageService>(
          create: (_) => SharedPrefsStorageService(),
        ),
        Provider<FirebaseService>(
          create: (_) => FirebaseServiceImpl(),
        ),
        Provider<TimerService>(
          create: (_) => TimerServiceImpl(),
          dispose: (_, service) => (service as TimerServiceImpl).dispose(),
        ),
        Provider<TtsService>(
          create: (_) => TtsServiceImpl(),
        ),

        // 저장소 레이어
        ProxyProvider2<FirebaseService, SharedPrefsStorageService,
            FirebaseRepository>(
          update: (_, firebaseService, storageService, __) =>
              FirebaseRepositoryImpl(
            firebaseService: firebaseService,
            storageService: storageService,
          ),
        ),
      ],
      child: child,
    );
  }
}
