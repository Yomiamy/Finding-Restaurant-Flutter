import 'package:equatable/equatable.dart';

import '../../../api/dto/yelp_restaurant_category_dto.dart';

sealed class FilterCuisineState extends Equatable {
  const FilterCuisineState();

  @override
  List<Object?> get props => [];
}

final class FilterCuisineInitial extends FilterCuisineState {
  const FilterCuisineInitial();
}

final class FilterCuisineLoading extends FilterCuisineState {
  const FilterCuisineLoading();
}

final class FilterCuisineLoaded extends FilterCuisineState {
  final List<YelpRestaurantCategoryDto> categories;

  const FilterCuisineLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}
