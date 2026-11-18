import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../models/model_barrel.dart';
import '../bloc/bloc_barrel.dart';
import 'cuisine_category_chips_widget.dart';
import 'section_card_widget.dart';
import 'segment_control_widget.dart';

class FilterPage extends StatefulWidget {
  static const routeName = '/FilterPage';

  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  int _priceIndex = 0;
  DateTime _openAtDateTime = DateTime.now();
  int _sortByIndex = 0;
  String? _selectedCategory;

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<FilterCuisineBloc>();
    if (bloc.state is FilterCuisineInitial) {
      bloc.add(const FetchFilterCuisines());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args =
          ModalRoute.of(context)?.settings.arguments
              as Tuple2<FilterConfigs, dynamic>?;
      final configs = args?.item1;
      if (configs != null) {
        _priceIndex = configs.priceIndex;
        _openAtDateTime = configs.openAtDateTime;
        _sortByIndex = configs.sortByIndex;
        _selectedCategory = configs.categories;
      }
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.colorfffbf7,
      appBar: AppBar(
        leading: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: ThemeColor.colorffffff),
        ),
        title: Text(
          S.current.filter_rules,
          style: const TextStyle(
            color: ThemeColor.colorffffff,
            fontSize: ThemeFontSize.fontSize22,
          ),
        ),
        backgroundColor: ThemeColor.colord84a20,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSize.space16,
            vertical: ThemeSize.space8,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SectionCardWidget(
                        icon: Icons.attach_money,
                        title: S.current.filter_price,
                        child: SegmentControlWidget(
                          initValue: _priceIndex,
                          segmentItems: [
                            S.current.filter_price_level1,
                            S.current.filter_price_level2,
                            S.current.filter_price_level3,
                            S.current.filter_price_level4,
                          ],
                          valueChange: (i) {
                            _priceIndex = i;
                          },
                        ),
                      ),
                      const SizedBox(height: ThemeSize.space16),
                      SectionCardWidget(
                        icon: Icons.access_time,
                        title: S.current.filter_business_hour,
                        child: Container(
                          height: ThemeSize.size180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              ThemeSize.radius8,
                            ),
                          ),
                          child: CupertinoDatePicker(
                            initialDateTime: _openAtDateTime,
                            use24hFormat: true,
                            mode: CupertinoDatePickerMode.dateAndTime,
                            onDateTimeChanged: (dateTime) {
                              _openAtDateTime = dateTime;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: ThemeSize.space16),
                      SectionCardWidget(
                        icon: Icons.restaurant_menu,
                        title: S.current.filter_cuisine_category,
                        child: _CuisineCategorySection(
                          selectedCategory: _selectedCategory,
                          onCategorySelected: (category) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: ThemeSize.space16),
                      SectionCardWidget(
                        icon: Icons.sort,
                        title: S.current.filter_sorting_rule,
                        child: SegmentControlWidget(
                          initValue: _sortByIndex,
                          segmentItems: [
                            S.current.filter_sorting_rule_best_match,
                            S.current.filter_sorting_rule_distance,
                            S.current.filter_sorting_rating,
                            S.current.filter_sorting_review_count,
                          ],
                          valueChange: (i) {
                            _sortByIndex = i;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ThemeSize.space16),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(ThemeSize.size48),
                  backgroundColor: ThemeColor.colord84a20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ThemeSize.radius12),
                  ),
                ),
                onPressed: () {
                  FilterConfigs configs = FilterConfigs.fromUI(
                    priceIndex: _priceIndex,
                    openAtDate: _openAtDateTime,
                    sortingRuleIndex: _sortByIndex,
                    categories: _selectedCategory,
                  );
                  Tuple2<FilterConfigs, dynamic> result = Tuple2(configs, null);
                  Navigator.pop(context, result);
                },
                child: Text(
                  S.current.apply,
                  style: const TextStyle(
                    fontSize: ThemeFontSize.fontSize18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CuisineCategorySection extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const _CuisineCategorySection({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCuisineBloc, FilterCuisineState>(
      builder: (context, state) => switch (state) {
        FilterCuisineInitial() || FilterCuisineLoading() => const SizedBox(
          height: ThemeSize.size48,
          child: Center(child: CupertinoActivityIndicator()),
        ),
        FilterCuisineLoaded(:final categories) => CuisineCategoryChipsWidget(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
        ),
      },
    );
  }
}
