import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities_barrel.dart';

sealed class AddToFoodMapState extends Equatable {
  const AddToFoodMapState();

  @override
  List<Object?> get props => [];
}

final class AddToFoodMapInitial extends AddToFoodMapState {
  const AddToFoodMapInitial();
}

final class AddToFoodMapLoading extends AddToFoodMapState {
  const AddToFoodMapLoading();
}

final class AddToFoodMapReady extends AddToFoodMapState {
  final List<FoodMapEntity> maps;
  final bool isSubmitting;
  final FoodMapErrorCode? errorCode;

  const AddToFoodMapReady({
    required this.maps,
    this.isSubmitting = false,
    this.errorCode,
  });

  AddToFoodMapReady copyWith({
    List<FoodMapEntity>? maps,
    bool? isSubmitting,
    FoodMapErrorCode? errorCode,
    bool clearError = false,
  }) {
    return AddToFoodMapReady(
      maps: maps ?? this.maps,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [maps, isSubmitting, errorCode];
}

final class AddToFoodMapSuccess extends AddToFoodMapState {
  final String mapTitle;
  final bool alreadyExists;

  const AddToFoodMapSuccess({
    required this.mapTitle,
    required this.alreadyExists,
  });

  @override
  List<Object?> get props => [mapTitle, alreadyExists];
}

final class AddToFoodMapFailure extends AddToFoodMapState {
  final FoodMapErrorCode errorCode;

  const AddToFoodMapFailure({required this.errorCode});

  @override
  List<Object?> get props => [errorCode];
}
