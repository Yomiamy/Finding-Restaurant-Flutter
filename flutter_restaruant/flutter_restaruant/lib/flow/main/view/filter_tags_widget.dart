import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/main_bloc.dart';
import '../../../model/filter_configs.dart';
import '../../../features/foundation/style/style.dart';
import '../../../features/foundation/constants/app_constants.dart';

import 'main_page.dart';

class FilterTagsWidget extends StatelessWidget {
  final FilterConfigs _filterConfigs;
  final LinkedHashMap<FilterConfigType, String> _filterConfigsMap =
      LinkedHashMap<FilterConfigType, String>();

  FilterTagsWidget({super.key, required FilterConfigs filterConfigs})
      : _filterConfigs = filterConfigs {
    if (_filterConfigs.sortBy != null && _filterConfigs.sortBy!.isNotEmpty) {
      _filterConfigsMap[FilterConfigType.sortingRule] =
          _filterConfigs.getSortingRuleDispStr(_filterConfigs.sortBy!);
    }

    if (_filterConfigs.price != null && _filterConfigs.price! > 0) {
      _filterConfigsMap[FilterConfigType.price] =
          _filterConfigs.getPriceDispStr(_filterConfigs.price!);
    }

    if (_filterConfigs.openAt != null && _filterConfigs.openAt! > 0) {
      _filterConfigsMap[FilterConfigType.openAt] = _filterConfigs.openAtDispStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_filterConfigsMap.isEmpty) {
      return const SizedBox.shrink();
    }

    final keys = _filterConfigsMap.keys.toList();
    final values = _filterConfigsMap.values.toList();

    return SizedBox(
      height: 50,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(keys.length, (index) {
              final type = keys[index];
              final title = values[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sizes.space4),
                child: FilterChip(
                  label: Text(
                    title,
                    style: const TextStyle(fontSize: UIConstants.xhFontSize),
                  ),
                  selected: true,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: const TextStyle(color: Colors.white),
                  onSelected: (_) {
                    context
                        .findAncestorStateOfType<MainPageState>()
                        ?.updateState(() {
                      final mainBloc = BlocProvider.of<MainBloc>(context);
                      _filterConfigs.clearConfig(type);
                      mainBloc.add(const Reset());
                    });
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
