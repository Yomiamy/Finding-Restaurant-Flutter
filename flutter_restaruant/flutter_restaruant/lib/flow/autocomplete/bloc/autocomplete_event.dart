import 'package:equatable/equatable.dart';

sealed class AutocompleteEvent extends Equatable {
  const AutocompleteEvent();

  @override
  List<Object?> get props => [];
}

final class AutocompleteQueryChanged extends AutocompleteEvent {
  final String query;
  final double? latitude;
  final double? longitude;

  const AutocompleteQueryChanged(
    this.query, {
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [query, latitude, longitude];
}

final class AutocompleteCleared extends AutocompleteEvent {
  const AutocompleteCleared();
}
