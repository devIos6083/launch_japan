// lib/viewmodels/auth_viewmodel.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:launch/services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

class AuthViewModel with ChangeNotifier {
  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthViewModel({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    _init();
  }

  // 상태 및 사용자 접근자
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // 초기화
  Future<void> _init() async {
    _authRepository.authStateChanges.listen((User? user) {
      _user = user;
      _status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      _isInitialized = true;
      notifyListeners();
    });
  }

  // 이메일/비밀번호 로그인
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final user =
          await _authRepository.signInWithEmailAndPassword(email, password);

      _user = user;
      _status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();

      return user != null;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // 이메일/비밀번호 회원가입
  Future<bool> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final user = await _authRepository.signUpWithEmailAndPassword(
          email, password, name);

      _user = user;
      _status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();

      return user != null;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // 구글 로그인
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final user = await _authRepository.signInWithGoogle();

      _user = user;
      _status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();

      return user != null;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // 카카오 로그인
  Future<bool> signInWithKakao() async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final user = await _authRepository.signInWithKakao();

      _user = user;
      _status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();

      return user != null;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // 비밀번호 재설정
  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      notifyListeners();

      await _authRepository.resetPassword(email);

      return true;
    } catch (e) {
      _errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // 로그인 상태 확인
  Future<bool> checkAuthStatus() async {
    try {
      final currentUser = await _authRepository.getCurrentUser();
      final isLoggedIn = await _authRepository.isUserLoggedIn();

      _user = currentUser;
      _status = (currentUser != null && isLoggedIn)
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;

      notifyListeners();
      return _status == AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // 오류 메시지 처리
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return '유효하지 않은 이메일 형식입니다.';
        case 'user-disabled':
          return '이 계정은 비활성화되었습니다.';
        case 'user-not-found':
          return '등록되지 않은 이메일입니다.';
        case 'wrong-password':
          return '비밀번호가 일치하지 않습니다.';
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다.';
        case 'operation-not-allowed':
          return '이 방식의 로그인이 허용되지 않습니다.';
        case 'weak-password':
          return '보안에 취약한 비밀번호입니다.';
        default:
          return '인증 오류가 발생했습니다: ${error.message}';
      }
    } else {
      return '로그인 중 오류가 발생했습니다.';
    }
  }

  // 에러 상태 초기화
  void resetError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status =
          _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
