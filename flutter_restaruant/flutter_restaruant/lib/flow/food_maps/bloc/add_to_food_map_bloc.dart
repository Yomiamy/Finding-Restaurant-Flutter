import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';
import 'add_to_food_map_event.dart';
import 'add_to_food_map_state.dart';

/// 管理「將餐廳加入共編美食地圖」BottomSheet 流程的 BLoC。
class AddToFoodMapBloc extends Bloc<AddToFoodMapEvent, AddToFoodMapState> {
  final FoodMapRepository? _repository;
  final Logger _logger;

  AddToFoodMapBloc({FoodMapRepository? repository, Logger? logger})
    : _repository = repository,
      _logger = logger ?? Logger(),
      super(const AddToFoodMapInitial()) {
    on<LoadMapsForAdd>(_onLoad);
    on<SubmitAddRestaurantToMap>(_onSubmitAdd);
    on<CreateMapAndAddRestaurant>(_onCreateAndAdd);
  }

  factory AddToFoodMapBloc.fromGetIt({Logger? logger}) {
    final getIt = GetIt.I;
    return AddToFoodMapBloc(
      repository: getIt.isRegistered<FoodMapRepository>()
          ? getIt<FoodMapRepository>()
          : null,
      logger: logger,
    );
  }

  Future<void> _onLoad(
    LoadMapsForAdd event,
    Emitter<AddToFoodMapState> emit,
  ) async {
    final repository = _repository;
    if (repository == null) {
      emit(const AddToFoodMapFailure(errorCode: FoodMapErrorCode.unknown));
      return;
    }

    emit(const AddToFoodMapLoading());
    try {
      final maps = await repository.fetchMyFoodMaps();
      emit(AddToFoodMapReady(maps: maps));
    } on FoodMapException catch (e, st) {
      _logger.w('LoadMapsForAdd failed', error: e, stackTrace: st);
      emit(AddToFoodMapFailure(errorCode: e.code));
    } on Exception catch (e, st) {
      _logger.e('LoadMapsForAdd unexpected failure', error: e, stackTrace: st);
      emit(const AddToFoodMapFailure(errorCode: FoodMapErrorCode.unknown));
    }
  }

  Future<void> _onSubmitAdd(
    SubmitAddRestaurantToMap event,
    Emitter<AddToFoodMapState> emit,
  ) async {
    final current = state;
    if (current is AddToFoodMapReady && current.isSubmitting) return;
    final repository = _repository;
    final currentMaps = current is AddToFoodMapReady
        ? current.maps
        : const <FoodMapEntity>[];
    if (repository == null) {
      emit(const AddToFoodMapFailure(errorCode: FoodMapErrorCode.unknown));
      return;
    }

    emit(AddToFoodMapReady(maps: currentMaps, isSubmitting: true));
    try {
      final result = await repository.addRestaurant(
        mapId: event.mapId,
        restaurant: event.restaurant,
        note: event.note,
      );
      emit(
        AddToFoodMapSuccess(
          mapTitle: event.mapTitle,
          alreadyExists: !result.added,
        ),
      );
    } on FoodMapException catch (e, st) {
      _logger.w('SubmitAddRestaurantToMap failed', error: e, stackTrace: st);
      emit(AddToFoodMapReady(maps: currentMaps, errorCode: e.code));
    } on Exception catch (e, st) {
      _logger.e(
        'SubmitAddRestaurantToMap unexpected failure',
        error: e,
        stackTrace: st,
      );
      emit(
        AddToFoodMapReady(
          maps: currentMaps,
          errorCode: FoodMapErrorCode.unknown,
        ),
      );
    }
  }

  Future<void> _onCreateAndAdd(
    CreateMapAndAddRestaurant event,
    Emitter<AddToFoodMapState> emit,
  ) async {
    final current = state;
    if (current is AddToFoodMapReady && current.isSubmitting) return;
    final repository = _repository;
    final currentMaps = current is AddToFoodMapReady
        ? current.maps
        : const <FoodMapEntity>[];
    if (repository == null) {
      emit(const AddToFoodMapFailure(errorCode: FoodMapErrorCode.unknown));
      return;
    }

    // 預檢所有欄位，避免短評超長或無效 restaurantId 導致已建出孤兒空地圖後才加入失敗。
    final trimmedTitle = event.title.trim();
    final trimmedDescription = event.description.trim();
    final trimmedNote = event.note.trim();
    final rawRestaurantId = (event.restaurant.id ?? '').trim();
    final hasValidRestaurantId =
        rawRestaurantId.isNotEmpty &&
        !rawRestaurantId.contains('/') &&
        rawRestaurantId != '.' &&
        rawRestaurantId != '..';

    if (trimmedTitle.isEmpty ||
        trimmedTitle.length > FoodMapEntity.maxTitleLength ||
        trimmedDescription.length > FoodMapEntity.maxDescriptionLength ||
        trimmedNote.length > FoodMapItemEntity.maxNoteLength ||
        !hasValidRestaurantId) {
      emit(
        AddToFoodMapReady(
          maps: currentMaps,
          errorCode: FoodMapErrorCode.invalidInput,
        ),
      );
      return;
    }

    emit(AddToFoodMapReady(maps: currentMaps, isSubmitting: true));
    FoodMapEntity? created;
    try {
      created = await repository.createFoodMap(
        title: trimmedTitle,
        description: trimmedDescription,
      );
      final result = await repository.addRestaurant(
        mapId: created.id,
        restaurant: event.restaurant,
        note: trimmedNote,
      );
      emit(
        AddToFoodMapSuccess(
          mapTitle: created.title,
          alreadyExists: !result.added,
        ),
      );
    } on FoodMapException catch (e, st) {
      _logger.w('CreateMapAndAddRestaurant failed', error: e, stackTrace: st);
      final createdMap = created;
      final nextMaps = createdMap == null
          ? currentMaps
          : [createdMap, ...currentMaps.where((m) => m.id != createdMap.id)];
      emit(AddToFoodMapReady(maps: nextMaps, errorCode: e.code));
    } on Exception catch (e, st) {
      _logger.e(
        'CreateMapAndAddRestaurant unexpected failure',
        error: e,
        stackTrace: st,
      );
      final createdMap = created;
      final nextMaps = createdMap == null
          ? currentMaps
          : [createdMap, ...currentMaps.where((m) => m.id != createdMap.id)];
      emit(
        AddToFoodMapReady(maps: nextMaps, errorCode: FoodMapErrorCode.unknown),
      );
    }
  }
}
