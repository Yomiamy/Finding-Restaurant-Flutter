import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities_barrel.dart';

sealed class ImportFavoritesState extends Equatable {
  const ImportFavoritesState();

  @override
  List<Object?> get props => [];
}

final class ImportFavoritesInitial extends ImportFavoritesState {
  const ImportFavoritesInitial();
}

final class ImportFavoritesLoading extends ImportFavoritesState {
  const ImportFavoritesLoading();
}

final class ImportFavoritesReady extends ImportFavoritesState {
  final List<RestaurantEntity> favorites;
  final bool isSubmitting;
  final FoodMapErrorCode? errorCode;

  const ImportFavoritesReady({
    required this.favorites,
    this.isSubmitting = false,
    this.errorCode,
  });

  @override
  List<Object?> get props => [favorites, isSubmitting, errorCode];
}

final class ImportFavoritesSuccess extends ImportFavoritesState {
  final int addedCount;
  final int skippedCount;

  const ImportFavoritesSuccess({
    required this.addedCount,
    required this.skippedCount,
  });

  @override
  List<Object?> get props => [addedCount, skippedCount];
}

final class ImportFavoritesFailure extends ImportFavoritesState {
  final FoodMapErrorCode errorCode;

  const ImportFavoritesFailure({required this.errorCode});

  @override
  List<Object?> get props => [errorCode];
}
