import 'package:flutter/material.dart';
import 'package:launch/core/theme/app_theme.dart.dart';
import 'package:provider/provider.dart';
import 'package:launch/di/locator.dart';
import 'package:launch/viewmodels/auth_viewmodel.dart';
import 'package:launch/viewmodels/activity_viewmodel.dart';
import 'package:launch/viewmodels/countdown_viewmodel.dart';
import 'package:launch/viewmodels/timer_viewmodel.dart';
import 'package:launch/viewmodels/profile_viewmodel.dart';
import 'package:launch/views/splash/splash_screen.dart';
import 'package:launch/views/auth/login_screen.dart';
import 'package:launch/views/auth/register_screen.dart';
import 'package:launch/views/home/home_screen.dart';
import 'package:launch/views/home/activity_selection_screen.dart';
import 'package:launch/views/countdown/countdown_screen.dart';
import 'package:launch/views/timer/focus_timer_screen.dart';
import 'package:launch/views/profile/profile_screen.dart';

class LaunchModeApp extends StatelessWidget {
  const LaunchModeApp({super.key});

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
        theme: AppTheme.theme,
        initialRoute: '/splash',
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
