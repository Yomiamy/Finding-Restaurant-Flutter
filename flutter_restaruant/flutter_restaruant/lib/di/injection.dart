import 'package:get_it/get_it.dart';
import '../api/api_clz.dart';
import '../api/dio/dio_client.dart';
import '../data_layer/repositories/favor_repo.dart';
import '../data_layer/repositories/main_repo.dart';
import '../data_layer/repositories/restaurant_detail_repo.dart';
import '../data_layer/repositories/settings_repo.dart';
import '../data_layer/repositories/sign_in_repo.dart';
import '../domain/repositories/favor_repository.dart';
import '../domain/repositories/main_repository.dart';
import '../domain/repositories/restaurant_detail_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/sign_in_repository.dart';
import '../manager/ad_counter_manager.dart';
import '../manager/fcm_manager.dart';
import '../manager/sign_in_manager.dart';

final getIt = GetIt.instance;

void setupInjection() {
  // Network services
  getIt.registerLazySingleton<DioClient>(() => dioClient);
  getIt.registerLazySingleton<APIClz>(() => APIClz(getIt<DioClient>().dio));

  // Managers
  getIt.registerLazySingleton<SignInManager>(() => SignInManager());
  getIt.registerLazySingleton<FcmManager>(() => FcmManager());
  getIt.registerLazySingleton<AdCounterManager>(() => AdCounterManager());

  // Repositories
  getIt.registerLazySingleton<MainRepository>(() => MainRepo());
  getIt.registerLazySingleton<RestaurantDetailRepository>(
      () => RestaurantDetailRepo());
  getIt.registerLazySingleton<FavorRepository>(() => FavorRepo());
  getIt.registerLazySingleton<SignInRepository>(() => SignInRepo());
  getIt.registerLazySingleton<SettingsRepository>(
      () => const SettingsRepo());
}
