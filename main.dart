import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:launch/firebase_options.dart';
import 'package:launch/di/locator.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:launch/views/auth/login_screen.dart';
import 'package:launch/views/auth/register_screen.dart';
import 'package:launch/views/countdown/countdown_screen.dart';
import 'package:launch/views/home/activity_selection_screen.dart';
import 'package:launch/views/home/home_screen.dart';
import 'package:launch/views/profile/profile_screen.dart';
import 'package:launch/views/splash/splash_screen.dart';
import 'package:launch/views/timer/focus_timer_screen.dart';
import 'package:provider/provider.dart';
import 'package:launch/viewmodels/auth_viewmodel.dart';
import 'package:launch/viewmodels/activity_viewmodel.dart';
import 'package:launch/viewmodels/countdown_viewmodel.dart';
import 'package:launch/viewmodels/timer_viewmodel.dart';
import 'package:launch/viewmodels/profile_viewmodel.dart';
import 'config/api_keys.dart';

Future<void> main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Realtime Database 설정 (선택적)
  FirebaseDatabase.instance.setPersistenceEnabled(true); // 오프라인 캐싱 활성화
  FirebaseDatabase.instance.setLoggingEnabled(true); // 개발 중 로깅 활성화

  // 의존성 주입 설정
  setupLocator();
  kakao.KakaoSdk.init(nativeAppKey: ApiKeys.kakaoNativeAppKey);

  // 상태 바 스타일 설정 (다크 테마)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 화면 방향 고정 (세로 모드)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locator<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<ActivityViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<CountdownViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<TimerViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<ProfileViewModel>()),
      ],
      child: MaterialApp(
        title: 'LAUNCH MODE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          primaryColor: const Color(0xFFFF5A3D),
        ),
        home: const SplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/activity_selection': (context) => const ActivitySelectionScreen(),
          '/countdown': (context) => const CountdownScreen(),
          '/focus_timer': (context) => const FocusTimerScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
