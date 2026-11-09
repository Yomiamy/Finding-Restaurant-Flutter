import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../api/dto/dto_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/tuple.dart';
import '../../../generated/l10n.dart';
import '../../restaurant/view/restaurant_detail_page.dart';
import '../bloc/autocomplete_barrel.dart';

class RestaurantSearchDelegate extends SearchDelegate<String?> {
  final AutocompleteBloc _bloc;
  final double? latitude;
  final double? longitude;
  String? _lastQuery;

  RestaurantSearchDelegate({
    required AutocompleteBloc bloc,
    this.latitude,
    this.longitude,
  }) : _bloc = bloc;

  @override
  String? get searchFieldLabel => S.current.autocomplete_search_hint;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: ThemeColor.colord84a20,
        iconTheme: const IconThemeData(color: ThemeColor.colorffffff),
        titleTextStyle: const TextStyle(
          color: ThemeColor.colorffffff,
          fontSize: ThemeFontSize.fontSize18,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(
          color: ThemeColor.colorffffff,
          fontSize: ThemeFontSize.fontSize16,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          key: const Key('autocomplete_clear_button'),
          icon: const Icon(Icons.clear, color: ThemeColor.colorffffff),
          onPressed: () {
            query = '';
            _bloc.add(const AutocompleteCleared());
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      key: const Key('autocomplete_back_button'),
      icon: const Icon(Icons.arrow_back, color: ThemeColor.colorffffff),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        close(context, trimmed);
      });
    }
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query != _lastQuery) {
      _lastQuery = query;
      _bloc.add(
        AutocompleteQueryChanged(
          query,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }

    return BlocBuilder<AutocompleteBloc, AutocompleteState>(
      bloc: _bloc,
      builder: (context, state) {
        return switch (state) {
          AutocompleteInitial() => _buildEmptyOrInitial(context),
          AutocompleteLoading() => const Center(
              child: Padding(
                padding: EdgeInsets.all(ThemeSize.space20),
                child: CircularProgressIndicator(),
              ),
            ),
          AutocompleteEmpty() => Center(
              child: Text(
                S.current.autocomplete_no_results,
                style: const TextStyle(
                  color: ThemeColor.color9e9e9e,
                  fontSize: ThemeFontSize.fontSize16,
                ),
              ),
            ),
          AutocompleteFailure(:final message) => Center(
              child: Text(
                message,
                style: const TextStyle(
                  color: ThemeColor.colorf44336,
                  fontSize: ThemeFontSize.fontSize14,
                ),
              ),
            ),
          AutocompleteSuccess(
            :final terms,
            :final businesses,
            :final categories,
          ) =>
            _buildSuggestionsList(
              context,
              terms: terms,
              businesses: businesses,
              categories: categories,
            ),
        };
      },
    );
  }

  Widget _buildEmptyOrInitial(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search,
            size: ThemeSize.size48,
            color: ThemeColor.color9e9e9e,
          ),
          const SizedBox(height: ThemeSize.space12),
          Text(
            S.current.autocomplete_search_hint,
            style: const TextStyle(
              color: ThemeColor.color9e9e9e,
              fontSize: ThemeFontSize.fontSize16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(
    BuildContext context, {
    required List<YelpAutocompleteTermDto> terms,
    required List<YelpRestaurantSummaryDto> businesses,
    required List<YelpRestaurantCategoryDto> categories,
  }) {
    return ListView(
      children: [
        if (terms.isNotEmpty) ...[
          _buildSectionHeader(S.current.autocomplete_suggestions_title),
          ...terms.map((term) {
            final text = term.text ?? '';
            return ListTile(
              leading: const Icon(Icons.search, color: ThemeColor.color9e9e9e),
              title: Text(text),
              onTap: () => close(context, text),
            );
          }),
        ],
        if (businesses.isNotEmpty) ...[
          _buildSectionHeader(S.current.autocomplete_businesses_title),
          ...businesses.map((business) {
            final name = business.name ?? '';
            final address = business.location?.displayAddress?.join(' ');
            return ListTile(
              leading: const Icon(Icons.storefront, color: ThemeColor.colord84a20),
              title: Text(name),
              subtitle: address != null && address.isNotEmpty ? Text(address) : null,
              onTap: () {
                Navigator.of(context).pushNamed(
                  RestaurantDetailPage.routeName,
                  arguments: Tuple2(RestaurantEntity.fromDto(business), null),
                );
              },
            );
          }),
        ],
        if (categories.isNotEmpty) ...[
          _buildSectionHeader(S.current.autocomplete_categories_title),
          ...categories.map((category) {
            final title = category.title ?? category.alias ?? '';
            return ListTile(
              leading: const Icon(Icons.category_outlined, color: ThemeColor.color9e9e9e),
              title: Text(title),
              onTap: () => close(context, title),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      color: ThemeColor.colorfffbf7,
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space16,
        vertical: ThemeSize.space8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: ThemeColor.color8a000000,
          fontWeight: FontWeight.bold,
          fontSize: ThemeFontSize.fontSize14,
        ),
      ),
    );
  }
}
