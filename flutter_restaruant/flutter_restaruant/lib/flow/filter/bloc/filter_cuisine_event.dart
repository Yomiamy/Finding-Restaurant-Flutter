import 'package:equatable/equatable.dart';

sealed class FilterCuisineEvent extends Equatable {
  const FilterCuisineEvent();

  @override
  List<Object?> get props => [];
}

final class FetchFilterCuisines extends FilterCuisineEvent {
  const FetchFilterCuisines();
}
