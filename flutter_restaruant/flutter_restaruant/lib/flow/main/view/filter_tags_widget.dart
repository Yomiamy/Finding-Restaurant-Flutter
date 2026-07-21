import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/flow/main/bloc/main_bloc.dart';
import 'package:flutter_restaruant/model/filter_configs.dart';
import 'package:flutter_restaruant/utils/ui_constants.dart';

import 'main_page.dart';

class FilterTagsWidget extends StatelessWidget {
  final FilterConfigs _filterConfigs;
  final LinkedHashMap<FilterConfigType, String> _filterConfigsMap =
      LinkedHashMap<FilterConfigType, String>();

  FilterTagsWidget({Key? key, required FilterConfigs filterConfigs})
      : _filterConfigs = filterConfigs,
        super(key: key) {
    if (_filterConfigs.sortBy != null &&
        _filterConfigs.sortBy!.isNotEmpty) {
      _filterConfigsMap[FilterConfigType.SORTING_RULE] =
          _filterConfigs.getSortingRuleDispStr(_filterConfigs.sortBy!);
    }

    if (_filterConfigs.price != null && _filterConfigs.price! > 0) {
      _filterConfigsMap[FilterConfigType.PRICE] =
          _filterConfigs.getPriceDispStr(_filterConfigs.price!);
    }

    if (_filterConfigs.openAt != null && _filterConfigs.openAt! > 0) {
      _filterConfigsMap[FilterConfigType.OPEN_AT] =
          _filterConfigs.openAtDispStr;
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
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FilterChip(
                  label: Text(
                    title,
                    style: TextStyle(fontSize: UIConstants.xhFontSize),
                  ),
                  selected: true,
                  selectedColor: Theme.of(context).primaryColor,
                  checkmarkColor: Colors.white,
                  labelStyle: const TextStyle(color: Colors.white),
                  onSelected: (_) {
                    context
                        .findAncestorStateOfType<MainPageState>()
                        ?.updateState(() {
                      final mainBloc = BlocProvider.of<MainBloc>(context);
                      _filterConfigs.clearConfig(type);
                      mainBloc.add(Reset());
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

