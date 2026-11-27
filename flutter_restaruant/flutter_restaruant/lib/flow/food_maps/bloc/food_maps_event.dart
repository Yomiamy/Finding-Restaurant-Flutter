import 'dart:async';

import 'package:equatable/equatable.dart';

abstract class FoodMapsEvent extends Equatable {
  const FoodMapsEvent();

  @override
  List<Object?> get props => [];
}

class FetchFoodMaps extends FoodMapsEvent {
  const FetchFoodMaps();
}

class RefreshFoodMaps extends FoodMapsEvent {
  final Completer<void>? completer;

  const RefreshFoodMaps({this.completer});
}

class CreateFoodMapRequested extends FoodMapsEvent {
  final String title;
  final String description;

  const CreateFoodMapRequested({required this.title, this.description = ''});

  @override
  List<Object?> get props => [title, description];
}

class JoinFoodMapByCodeRequested extends FoodMapsEvent {
  final String inviteCode;

  const JoinFoodMapByCodeRequested({required this.inviteCode});

  @override
  List<Object?> get props => [inviteCode];
}

class DeleteFoodMapRequested extends FoodMapsEvent {
  final String mapId;

  const DeleteFoodMapRequested({required this.mapId});

  @override
  List<Object?> get props => [mapId];
}

class LeaveFoodMapRequested extends FoodMapsEvent {
  final String mapId;

  const LeaveFoodMapRequested({required this.mapId});

  @override
  List<Object?> get props => [mapId];
}
