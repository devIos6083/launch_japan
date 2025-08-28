// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:firebase_database/firebase_database.dart';
import 'package:launch/services/activity_service.dart';
import 'package:launch/services/storage_service.dart';
import 'package:launch/services/timer_service.dart';
import 'package:launch/services/tts_service.dart';
import 'package:launch/services/user_service.dart' as app_user;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 인증 서비스 인터페이스
abstract class AuthService {
  // 기본 인증 메서드
  Future<User?> getCurrentUser();
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<User?> signUpWithEmailAndPassword(
      String email, String password, String name);
  Future<User?> signInWithGoogle();
  Future<User?> signInWithKakao();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Stream<User?> get authStateChanges;

  // 사용자 정보 관리 메서드
  Future<void> createUserInDatabase(User user, app_user.LoginProvider provider,
      [String? displayName, String? photoUrl]);
  Future<void> updateUserLastLogin(String userId);
}

/// 인증 서비스 구현 클래스
class AuthServiceImpl implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 참조 경로
  String get _usersPath => 'users';

  @override
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  @override
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 마지막 로그인 시간 업데이트
      await updateUserLastLogin(userCredential.user!.uid);

      return userCredential.user;
    } catch (e) {
      print('이메일 로그인 오류: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 사용자 프로필 업데이트
      await userCredential.user?.updateDisplayName(name);

      // Realtime Database에 사용자 데이터 저장
      await createUserInDatabase(
        userCredential.user!,
        app_user.LoginProvider.email,
      );

      return userCredential.user;
    } catch (e) {
      print('이메일 회원가입 오류: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      // 구글 로그인 진행
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 구글 인증 정보 얻기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 인증 정보 생성
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase로 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      // 사용자가 처음 로그인한 경우 Realtime Database에 데이터 생성
      await createUserInDatabase(
        userCredential.user!,
        app_user.LoginProvider.google,
      );

      return userCredential.user;
    } catch (e) {
      print('구글 로그인 오류: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signInWithKakao() async {
    try {
      // 카카오톡 설치 여부 확인
      if (await kakao.isKakaoTalkInstalled()) {
        await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 카카오 사용자 정보 얻기
      User? user = await _handleKakaoLogin();
      return user;
    } catch (e) {
      print('카카오 로그인 오류: $e');
      rethrow;
    }
  }

  // 카카오 로그인 처리
  Future<User?> _handleKakaoLogin() async {
    try {
      // 카카오 사용자 정보 요청
      kakao.User kakaoUser = await kakao.UserApi.instance.me();

      // 파이어베이스 커스텀 토큰 만들기 (서버 필요 - 여기서는 예시)
      // 실제 구현에서는 서버 엔드포인트 호출 필요
      // final customToken = await _getFirebaseCustomToken(kakaoUser.id);

      // 커스텀 토큰으로 Firebase 인증
      // final userCredential = await _auth.signInWithCustomToken(customToken);

      // 임시 처리: 이메일로 가입 (실제 구현에서는 위 주석 코드 활용)
      final kakaoEmail =
          kakaoUser.kakaoAccount?.email ?? '${kakaoUser.id}@kakao.com';

      // 기존 이메일이 있는지 확인
      try {
        // 먼저 로그인 시도 (기존 계정 있는 경우)
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: kakaoEmail,
          password: 'kakao_${kakaoUser.id}', // 실제 구현에서는 안전한 방법 필요
        );

        // 마지막 로그인 시간 업데이트
        await updateUserLastLogin(userCredential.user!.uid);

        return userCredential.user;
      } catch (e) {
        // 로그인 실패 시 회원가입 진행
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: kakaoEmail,
          password: 'kakao_${kakaoUser.id}', // 실제 구현에서는 안전한 방법 필요
        );

        // 사용자가 처음 로그인한 경우 Realtime Database에 데이터 생성
        await createUserInDatabase(
          userCredential.user!,
          app_user.LoginProvider.kakao,
          kakaoUser.kakaoAccount?.profile?.nickname,
          kakaoUser.kakaoAccount?.profile?.profileImageUrl,
        );

        return userCredential.user;
      }
    } catch (e) {
      print('카카오 로그인 처리 오류: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      // 카카오 로그아웃
      try {
        await kakao.UserApi.instance.logout();
      } catch (e) {
        // 카카오 로그아웃 에러는 무시
        print('카카오 로그아웃 오류 (무시됨): $e');
      }
    } catch (e) {
      print('로그아웃 오류: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('비밀번호 재설정 이메일 전송 오류: $e');
      rethrow;
    }
  }

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 외부에서도 접근할 수 있도록 public으로 변경
  @override
  Future<void> createUserInDatabase(
    User user,
    app_user.LoginProvider provider, [
    String? displayName,
    String? photoUrl,
  ]) async {
    try {
      final userRef = _database.ref().child('$_usersPath/${user.uid}');
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        final now = DateTime.now();

        final newUser = app_user.UserProfile(
          id: user.uid,
          email: user.email ?? '',
          displayName: displayName ?? user.displayName,
          photoUrl: photoUrl ?? user.photoURL,
          createdAt: now,
          lastLoginAt: now,
          loginProvider: provider,
        );

        // toJson을 통해 변환 (DateTime은 이미 String으로 변환됨)
        final userData = newUser.toJson();

        // id는 경로에 포함되어 있으므로 제외
        userData.remove('id');

        await userRef.set(userData);
        print('사용자 데이터베이스 생성 완료: ${user.uid}');
      } else {
        // 이미 존재하는 사용자면 마지막 로그인 시간만 업데이트
        await updateUserLastLogin(user.uid);
      }
    } catch (e) {
      print('사용자 데이터베이스 생성 오류: $e');
      rethrow;
    }
  }

  // 외부에서도 접근할 수 있도록 public으로 변경
  @override
  Future<void> updateUserLastLogin(String userId) async {
    try {
      final now = DateTime.now();
      await _database.ref().child('$_usersPath/$userId').update({
        'lastLoginAt': now.toIso8601String(),
      });
      print('사용자 마지막 로그인 시간 업데이트 완료: $userId');
    } catch (e) {
      print('사용자 마지막 로그인 시간 업데이트 오류: $e');
      rethrow;
    }
  }
}

/// 인증 저장소 인터페이스
abstract class AuthRepository {
  // 기본 인증 기능
  Future<User?> getCurrentUser();
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<User?> signUpWithEmailAndPassword(
      String email, String password, String name);
  Future<User?> signInWithGoogle();
  Future<User?> signInWithKakao();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Stream<User?> get authStateChanges;

  // 로컬 세션 관리
  Future<void> saveUserSession(User user);
  Future<void> clearUserSession();
  Future<bool> isUserLoggedIn();

  // 현재 로그인한 사용자 정보
  String? get currentUserId;
  String? get currentUserEmail;
  String? get currentUserName;
  String? get currentUserPhoto;
}

/// 인증 저장소 구현 클래스
class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final SharedPrefsStorageService _storageService;

  // 로컬에 저장된 사용자 정보
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _userPhoto;
  bool _isLoggedIn = false;

  // 저장소 키
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhoto = 'user_photo';
  static const String _keyIsLoggedIn = 'is_logged_in';

  AuthRepositoryImpl({
    required AuthService authService,
    required SharedPrefsStorageService storageService,
  })  : _authService = authService,
        _storageService = storageService {
    // 초기화 시 로컬 세션 정보 불러오기
    _loadUserSession();
  }

  // 로컬에 저장된 사용자 세션 불러오기
  Future<void> _loadUserSession() async {
    try {
      _isLoggedIn = await _storageService.getBool(_keyIsLoggedIn) ?? false;

      if (_isLoggedIn) {
        _userId = await _storageService.getString(_keyUserId);
        _userEmail = await _storageService.getString(_keyUserEmail);
        _userName = await _storageService.getString(_keyUserName);
        _userPhoto = await _storageService.getString(_keyUserPhoto);

        print('사용자 세션 로드 완료: $_userName ($_userEmail)');
      }
    } catch (e) {
      print('사용자 세션 로드 오류: $e');
      _isLoggedIn = false;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    return _authService.getCurrentUser();
  }

  @override
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final user =
          await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        await saveUserSession(user);
      }
      return user;
    } catch (e) {
      print('이메일 로그인 저장소 오류: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final user =
          await _authService.signUpWithEmailAndPassword(email, password, name);
      if (user != null) {
        await saveUserSession(user);
      }
      return user;
    } catch (e) {
      print('이메일 회원가입 저장소 오류: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await saveUserSession(user);
      }
      return user;
    } catch (e) {
      print('구글 로그인 저장소 오류: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signInWithKakao() async {
    try {
      final user = await _authService.signInWithKakao();
      if (user != null) {
        await saveUserSession(user);
      }
      return user;
    } catch (e) {
      print('카카오 로그인 저장소 오류: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      await clearUserSession();
    } catch (e) {
      print('로그아웃 저장소 오류: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    return _authService.resetPassword(email);
  }

  @override
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  @override
  Future<void> saveUserSession(User user) async {
    try {
      // 메모리에 저장
      _userId = user.uid;
      _userEmail = user.email ?? '';
      _userName = user.displayName ?? '';
      _userPhoto = user.photoURL ?? '';
      _isLoggedIn = true;

      // 로컬 저장소에 저장
      await _storageService.setString(_keyUserId, _userId!);
      await _storageService.setString(_keyUserEmail, _userEmail!);
      await _storageService.setString(_keyUserName, _userName!);
      await _storageService.setString(_keyUserPhoto, _userPhoto!);
      await _storageService.setBool(_keyIsLoggedIn, true);

      print('사용자 세션 저장 완료: ${user.displayName} (${user.email})');
    } catch (e) {
      print('사용자 세션 저장 오류: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearUserSession() async {
    try {
      // 메모리에서 제거
      _userId = null;
      _userEmail = null;
      _userName = null;
      _userPhoto = null;
      _isLoggedIn = false;

      // 로컬 저장소에서 제거
      await _storageService.remove(_keyUserId);
      await _storageService.remove(_keyUserEmail);
      await _storageService.remove(_keyUserName);
      await _storageService.remove(_keyUserPhoto);
      await _storageService.setBool(_keyIsLoggedIn, false);

      print('사용자 세션 제거 완료');
    } catch (e) {
      print('사용자 세션 제거 오류: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isUserLoggedIn() async {
    // 이미 메모리에 로드된 값 사용
    if (_isLoggedIn) return true;

    // 로컬 저장소 확인
    final isLoggedIn = await _storageService.getBool(_keyIsLoggedIn) ?? false;

    // Firebase도 확인하여 동기화
    final currentUser = await _authService.getCurrentUser();
    return isLoggedIn && currentUser != null;
  }

  // 현재 로그인된 사용자 정보 접근자
  @override
  String? get currentUserId => _userId;

  @override
  String? get currentUserEmail => _userEmail;

  @override
  String? get currentUserName => _userName;

  @override
  String? get currentUserPhoto => _userPhoto;
}

// lib/providers/service_providers.dart (업데이트)
// lib/services/auth_service.dart의 마지막 부분 수정

/// 앱의 서비스 제공자 구성
class AuthServiceProviders extends StatelessWidget {
  final Widget child;

  const AuthServiceProviders({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider 타입을 SharedPrefsStorageService로 변경
        Provider<SharedPrefsStorageService>(
          create: (_) => SharedPrefsStorageService(),
          lazy: false, // 먼저 초기화
        ),
        Provider<AuthService>(
          create: (_) => AuthServiceImpl(),
        ),

        // ProxyProvider의 두 번째 타입 파라미터도 변경
        ProxyProvider2<AuthService, SharedPrefsStorageService, AuthRepository>(
          update: (_, authService, storageService, __) => AuthRepositoryImpl(
            authService: authService,
            storageService: storageService,
          ),
        ),
      ],
      child: child,
    );
  }
}
