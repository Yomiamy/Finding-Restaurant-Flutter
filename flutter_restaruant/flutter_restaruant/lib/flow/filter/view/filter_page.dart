import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../api/dto/yelp_restaurant_category_dto.dart';
import '../../../data_layer/repositories/yelp_category_repo.dart';
import '../../../domain/repositories/yelp_category_repository.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../models/model_barrel.dart';
import 'section_card_widget.dart';
import 'segment_control_widget.dart';

class FilterPage extends StatefulWidget {
  static const routeName = '/FilterPage';
  final YelpCategoryRepository? categoryRepository;

  const FilterPage({super.key, this.categoryRepository});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  int _priceIndex = 0;
  DateTime _openAtDateTime = DateTime.now();
  int _sortByIndex = 0;
  String? _selectedCategory;
  List<YelpRestaurantCategoryDto> _cuisineCategories = const [];
  bool _isLoadingCuisines = true;

  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args =
          ModalRoute.of(context)!.settings.arguments
              as Tuple2<FilterConfigs, dynamic>;
      final configs = args.item1;
      _priceIndex = configs.priceIndex;
      _openAtDateTime = configs.openAtDateTime;
      _sortByIndex = configs.sortByIndex;
      _selectedCategory = configs.categories;
      _isInit = true;
      _loadCuisineCategories();
    }
  }

  Future<void> _loadCuisineCategories() async {
    final repo =
        widget.categoryRepository ??
        (GetIt.I.isRegistered<YelpCategoryRepository>()
            ? GetIt.I<YelpCategoryRepository>()
            : null);

    if (repo == null) {
      if (mounted) {
        setState(() {
          _cuisineCategories = YelpCategoryRepo.defaultCuisines;
          _isLoadingCuisines = false;
        });
      }
      return;
    }

    try {
      final cuisines = await repo.fetchCuisineCategories();
      if (mounted) {
        setState(() {
          _cuisineCategories = cuisines;
          _isLoadingCuisines = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cuisineCategories = YelpCategoryRepo.defaultCuisines;
          _isLoadingCuisines = false;
        });
      }
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
                        child: _isLoadingCuisines
                            ? const SizedBox(
                                height: ThemeSize.size48,
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              )
                            : Wrap(
                                spacing: ThemeSize.space8,
                                runSpacing: ThemeSize.space8,
                                children: [
                                  ChoiceChip(
                                    label: Text(S.current.filter_cuisine_all),
                                    selected:
                                        _selectedCategory == null ||
                                        _selectedCategory!.isEmpty,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedCategory = null;
                                        });
                                      }
                                    },
                                  ),
                                  ..._cuisineCategories.map((category) {
                                    final isSelected =
                                        _selectedCategory == category.alias;
                                    return ChoiceChip(
                                      label: Text(
                                        category.title ?? category.alias ?? '',
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedCategory = selected
                                              ? category.alias
                                              : null;
                                        });
                                      },
                                    );
                                  }),
                                ],
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
