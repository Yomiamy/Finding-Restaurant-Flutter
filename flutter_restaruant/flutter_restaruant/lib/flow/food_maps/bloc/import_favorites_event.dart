import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities_barrel.dart';

abstract class ImportFavoritesEvent extends Equatable {
  const ImportFavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavoritesForImport extends ImportFavoritesEvent {
  const LoadFavoritesForImport();
}

class SubmitImportFavorites extends ImportFavoritesEvent {
  final String mapId;
  final List<RestaurantEntity> restaurants;

  const SubmitImportFavorites({required this.mapId, required this.restaurants});

  @override
  List<Object?> get props => [mapId, restaurants];
}
