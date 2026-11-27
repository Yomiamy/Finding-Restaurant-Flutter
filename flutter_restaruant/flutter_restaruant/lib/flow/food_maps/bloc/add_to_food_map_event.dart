import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities_barrel.dart';

abstract class AddToFoodMapEvent extends Equatable {
  const AddToFoodMapEvent();

  @override
  List<Object?> get props => [];
}

class LoadMapsForAdd extends AddToFoodMapEvent {
  const LoadMapsForAdd();
}

class SubmitAddRestaurantToMap extends AddToFoodMapEvent {
  final String mapId;
  final String mapTitle;
  final RestaurantEntity restaurant;
  final String note;

  const SubmitAddRestaurantToMap({
    required this.mapId,
    required this.mapTitle,
    required this.restaurant,
    this.note = '',
  });

  @override
  List<Object?> get props => [mapId, mapTitle, restaurant, note];
}

class CreateMapAndAddRestaurant extends AddToFoodMapEvent {
  final String title;
  final String description;
  final RestaurantEntity restaurant;
  final String note;

  const CreateMapAndAddRestaurant({
    required this.title,
    this.description = '',
    required this.restaurant,
    this.note = '',
  });

  @override
  List<Object?> get props => [title, description, restaurant, note];
}
