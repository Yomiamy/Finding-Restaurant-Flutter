import 'package:get_it/get_it.dart';
import '../api/api_barrel.dart';
import '../data_layer/datasources/datasources_barrel.dart';
import '../data_layer/repositories/repositories_barrel.dart';
import '../domain/repositories/repositories_barrel.dart';
import '../manager/manager_barrel.dart';

final getIt = GetIt.instance;

void setupInjection() {
  // Network services
  getIt.registerLazySingleton<DioClient>(() => dioClient);
  getIt.registerLazySingleton<APIClz>(() => APIClz(getIt<DioClient>().dio));

  // Managers
  getIt.registerLazySingleton<SignInManager>(() => SignInManager());
  getIt.registerLazySingleton<FcmManager>(() => FcmManager());
  getIt.registerLazySingleton<AdCounterManager>(() => AdCounterManager());

  // Data sources
  getIt.registerLazySingleton<FavorDataSource>(() => FavorDataSource());

  // Repositories
  getIt.registerLazySingleton<MainRepository>(
      () => MainRepo(favorDataSource: getIt<FavorDataSource>()));
  getIt.registerLazySingleton<RestaurantDetailRepository>(
      () => RestaurantDetailRepo(favorDataSource: getIt<FavorDataSource>()));
  getIt.registerLazySingleton<FavorRepository>(
      () => FavorRepo(favorDataSource: getIt<FavorDataSource>()));
  getIt.registerLazySingleton<SignInRepository>(() => SignInRepo());
  getIt.registerLazySingleton<SettingsRepository>(() => const SettingsRepo());
}
