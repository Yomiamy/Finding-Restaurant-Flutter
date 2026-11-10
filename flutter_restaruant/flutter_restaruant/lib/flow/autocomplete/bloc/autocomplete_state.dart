import 'package:equatable/equatable.dart';

import '../../../api/dto/dto_barrel.dart';

sealed class AutocompleteState extends Equatable {
  const AutocompleteState();

  @override
  List<Object?> get props => [];
}

final class AutocompleteInitial extends AutocompleteState {
  const AutocompleteInitial();
}

final class AutocompleteLoading extends AutocompleteState {
  const AutocompleteLoading();
}

final class AutocompleteSuccess extends AutocompleteState {
  final List<YelpAutocompleteTermDto> terms;
  final List<YelpRestaurantSummaryDto> businesses;
  final List<YelpRestaurantCategoryDto> categories;

  const AutocompleteSuccess({
    this.terms = const [],
    this.businesses = const [],
    this.categories = const [],
  });

  bool get isEmpty =>
      terms.isEmpty && businesses.isEmpty && categories.isEmpty;

  @override
  List<Object?> get props => [terms, businesses, categories];
}

final class AutocompleteEmpty extends AutocompleteState {
  const AutocompleteEmpty();
}

final class AutocompleteFailure extends AutocompleteState {
  final String message;

  const AutocompleteFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
