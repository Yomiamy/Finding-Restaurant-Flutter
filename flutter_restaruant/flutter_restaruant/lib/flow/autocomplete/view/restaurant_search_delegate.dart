import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../api/dto/dto_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/tuple.dart';
import '../../../generated/l10n.dart';
import '../../restaurant/view/restaurant_detail_page.dart';
import '../bloc/autocomplete_barrel.dart';

/// 餐廳關鍵字搜尋與 Yelp Autocomplete 聯想建議的 [SearchDelegate]。
///
/// 分區呈現熱門搜尋詞、推薦店家與相關分類；點選詞條或分類會回傳關鍵字，點選店家則導向詳情頁。
class RestaurantSearchDelegate extends SearchDelegate<String?> {
  final AutocompleteBloc _bloc;
  final double? latitude;
  final double? longitude;
  String? _lastQuery;
  bool _isClosingResults = false;

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
    if (trimmed.isNotEmpty && !_isClosingResults) {
      _isClosingResults = true;
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
          AutocompleteInitial() => const _AutocompleteInitialView(),
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
          AutocompleteFailure() => Center(
            child: Text(
              S.current.error_and_retry,
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
            _AutocompleteSuggestionsList(
              terms: terms,
              businesses: businesses,
              categories: categories,
              onSelectKeyword: (keyword) => close(context, keyword),
            ),
        };
      },
    );
  }
}

class _AutocompleteInitialView extends StatelessWidget {
  const _AutocompleteInitialView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        key: const Key('autocomplete_initial_view'),
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
}

class _AutocompleteSuggestionsList extends StatelessWidget {
  final List<YelpAutocompleteTermDto> terms;
  final List<YelpRestaurantSummaryDto> businesses;
  final List<YelpRestaurantCategoryDto> categories;
  final ValueChanged<String> onSelectKeyword;

  const _AutocompleteSuggestionsList({
    required this.terms,
    required this.businesses,
    required this.categories,
    required this.onSelectKeyword,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (terms.isNotEmpty) ...[
          _AutocompleteSectionHeader(
            title: S.current.autocomplete_suggestions_title,
          ),
          ...terms.map((term) {
            final text = term.text ?? '';
            return ListTile(
              leading: const Icon(Icons.search, color: ThemeColor.color9e9e9e),
              title: Text(text),
              onTap: () => onSelectKeyword(text),
            );
          }),
        ],
        if (businesses.isNotEmpty) ...[
          _AutocompleteSectionHeader(
            title: S.current.autocomplete_businesses_title,
          ),
          ...businesses.map((business) {
            final name = business.name ?? '';
            final address = business.location?.displayAddress?.join(' ');
            return ListTile(
              leading: const Icon(
                Icons.storefront,
                color: ThemeColor.colord84a20,
              ),
              title: Text(name),
              subtitle: address != null && address.isNotEmpty
                  ? Text(address)
                  : null,
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
          _AutocompleteSectionHeader(
            title: S.current.autocomplete_categories_title,
          ),
          ...categories.map((category) {
            final title = category.title ?? category.alias ?? '';
            return ListTile(
              leading: const Icon(
                Icons.category_outlined,
                color: ThemeColor.color9e9e9e,
              ),
              title: Text(title),
              onTap: () => onSelectKeyword(title),
            );
          }),
        ],
      ],
    );
  }
}

class _AutocompleteSectionHeader extends StatelessWidget {
  final String title;

  const _AutocompleteSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ThemeColor.colorfffbf7,
      child: Padding(
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
      ),
    );
  }
}
