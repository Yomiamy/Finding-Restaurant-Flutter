import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities_barrel.dart';

abstract class FoodMapDetailEvent extends Equatable {
  const FoodMapDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadFoodMapDetail extends FoodMapDetailEvent {
  final String mapId;
  final FoodMapEntity? initialMap;

  const LoadFoodMapDetail({required this.mapId, this.initialMap});

  @override
  List<Object?> get props => [mapId, initialMap];
}

class RefreshFoodMapDetail extends FoodMapDetailEvent {
  final String mapId;
  final Completer<void>? completer;

  const RefreshFoodMapDetail({required this.mapId, this.completer});

  @override
  List<Object?> get props => [mapId];
}

class ToggleFoodMapItemVote extends FoodMapDetailEvent {
  final String mapId;
  final String restaurantId;
  final FoodMapVote tappedVote;

  const ToggleFoodMapItemVote({
    required this.mapId,
    required this.restaurantId,
    required this.tappedVote,
  });

  @override
  List<Object?> get props => [mapId, restaurantId, tappedVote];
}

class UpdateFoodMapItemNoteRequested extends FoodMapDetailEvent {
  final String mapId;
  final String restaurantId;
  final String note;

  const UpdateFoodMapItemNoteRequested({
    required this.mapId,
    required this.restaurantId,
    required this.note,
  });

  @override
  List<Object?> get props => [mapId, restaurantId, note];
}

class RemoveFoodMapItemRequested extends FoodMapDetailEvent {
  final String mapId;
  final String restaurantId;

  const RemoveFoodMapItemRequested({
    required this.mapId,
    required this.restaurantId,
  });

  @override
  List<Object?> get props => [mapId, restaurantId];
}
