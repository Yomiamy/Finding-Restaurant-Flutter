import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';
import 'import_favorites_event.dart';
import 'import_favorites_state.dart';

/// 管理「從我的最愛批次匯入至共編美食地圖」BottomSheet 的 BLoC。
class ImportFavoritesBloc
    extends Bloc<ImportFavoritesEvent, ImportFavoritesState> {
  final FavorRepository? _favorRepository;
  final FoodMapRepository? _foodMapRepository;
  final Logger _logger;

  ImportFavoritesBloc({
    FavorRepository? favorRepository,
    FoodMapRepository? foodMapRepository,
    Logger? logger,
  }) : _favorRepository = favorRepository,
       _foodMapRepository = foodMapRepository,
       _logger = logger ?? Logger(),
       super(const ImportFavoritesInitial()) {
    on<LoadFavoritesForImport>(_onLoad);
    on<SubmitImportFavorites>(_onSubmit);
  }

  factory ImportFavoritesBloc.fromGetIt({Logger? logger}) {
    final getIt = GetIt.I;
    return ImportFavoritesBloc(
      favorRepository: getIt.isRegistered<FavorRepository>()
          ? getIt<FavorRepository>()
          : null,
      foodMapRepository: getIt.isRegistered<FoodMapRepository>()
          ? getIt<FoodMapRepository>()
          : null,
      logger: logger,
    );
  }

  Future<void> _onLoad(
    LoadFavoritesForImport event,
    Emitter<ImportFavoritesState> emit,
  ) async {
    final favorRepository = _favorRepository;
    final foodMapRepository = _foodMapRepository;
    if (favorRepository == null || foodMapRepository == null) {
      emit(const ImportFavoritesFailure(errorCode: FoodMapErrorCode.unknown));
      return;
    }

    emit(const ImportFavoritesLoading());
    try {
      final favorites = await favorRepository.fetchFavorInfos();
      emit(ImportFavoritesReady(favorites: favorites));
    } on Exception catch (e, st) {
      _logger.e('LoadFavoritesForImport failed', error: e, stackTrace: st);
      emit(const ImportFavoritesFailure(errorCode: FoodMapErrorCode.unknown));
    }
  }

  Future<void> _onSubmit(
    SubmitImportFavorites event,
    Emitter<ImportFavoritesState> emit,
  ) async {
    final current = state;
    if (current is ImportFavoritesReady && current.isSubmitting) return;
    final foodMapRepository = _foodMapRepository;
    final currentFavorites = current is ImportFavoritesReady
        ? current.favorites
        : const <RestaurantEntity>[];
    if (foodMapRepository == null) {
      emit(const ImportFavoritesFailure(errorCode: FoodMapErrorCode.unknown));
      return;
    }

    emit(ImportFavoritesReady(favorites: currentFavorites, isSubmitting: true));
    try {
      final result = await foodMapRepository.importRestaurants(
        mapId: event.mapId,
        restaurants: event.restaurants,
      );
      emit(
        ImportFavoritesSuccess(
          addedCount: result.addedCount,
          skippedCount: result.skippedCount,
        ),
      );
    } on FoodMapException catch (e, st) {
      _logger.w('SubmitImportFavorites failed', error: e, stackTrace: st);
      emit(
        ImportFavoritesReady(favorites: currentFavorites, errorCode: e.code),
      );
    } on Exception catch (e, st) {
      _logger.e(
        'SubmitImportFavorites unexpected failure',
        error: e,
        stackTrace: st,
      );
      emit(
        ImportFavoritesReady(
          favorites: currentFavorites,
          errorCode: FoodMapErrorCode.unknown,
        ),
      );
    }
  }
}
