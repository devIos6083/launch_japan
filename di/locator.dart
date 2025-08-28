// lib/services/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:launch/services/activity_service.dart';
import 'package:launch/services/auth_service.dart';
import 'package:launch/services/storage_service.dart';
import 'package:launch/services/timer_service.dart';
import 'package:launch/services/tts_service.dart';
import 'package:launch/services/user_service.dart';
import 'package:launch/viewmodels/auth_viewmodel.dart';
import 'package:launch/viewmodels/activity_viewmodel.dart';
import 'package:launch/viewmodels/countdown_viewmodel.dart';
import 'package:launch/viewmodels/timer_viewmodel.dart';
import 'package:launch/viewmodels/profile_viewmodel.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // 서비스 등록 (통합된 서비스 사용)
  locator.registerLazySingleton<FirebaseService>(() => FirebaseServiceImpl());
  locator.registerLazySingleton<AuthService>(() => AuthServiceImpl());
  locator.registerLazySingleton<TimerService>(() => TimerServiceImpl());
  locator.registerLazySingleton<SharedPrefsStorageService>(
      () => SharedPrefsStorageService());
  locator.registerLazySingleton<TtsService>(() => TtsServiceImpl());

  // 저장소 등록 (통합된 저장소 사용)
  locator.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        authService: locator<AuthService>(),
        storageService: locator<SharedPrefsStorageService>(),
      ));

  locator
      .registerLazySingleton<FirebaseRepository>(() => FirebaseRepositoryImpl(
            firebaseService: locator<FirebaseService>(),
            storageService: locator<SharedPrefsStorageService>(),
          ));

  // 뷰모델 등록 (Firebase 저장소 사용)
  locator.registerFactory<AuthViewModel>(() => AuthViewModel(
        authRepository: locator<AuthRepository>(),
      ));

  locator.registerFactory<ActivityViewModel>(() => ActivityViewModel(
        // ActivityRepository 대신 통합된 FirebaseRepository 사용
        activityRepository: locator<FirebaseRepository>(),
      ));

  locator.registerFactory<CountdownViewModel>(() => CountdownViewModel(
        timerService: locator<TimerService>(),
        ttsService: locator<TtsService>(),
      ));

  locator.registerFactory<TimerViewModel>(() => TimerViewModel(
        timerService: locator<TimerService>(),
        activityRepository: locator<FirebaseRepository>(), // 통합된 저장소 사용
      ));

  locator.registerFactory<ProfileViewModel>(() => ProfileViewModel(
        // UserRepository 대신 통합된 FirebaseRepository 사용
        userRepository: locator<FirebaseRepository>(),
        activityRepository:
            locator<FirebaseRepository>(), // 동일한 FirebaseRepository 사용
      ));
}
