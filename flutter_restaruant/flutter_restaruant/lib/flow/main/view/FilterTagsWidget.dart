import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_restaruant/flow/main/bloc/MainBloc.dart';
import 'package:flutter_restaruant/model/FilterConfigs.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_tags/flutter_tags.dart';

import 'MainPage.dart';

class FilterTagsWidget extends StatelessWidget {

  final GlobalKey<TagsState> _tagStateKey = GlobalKey<TagsState>();

  final FilterConfigs _filterConfigs;
  final LinkedHashMap<FilterConfigType, String> _filterConfigsMap= LinkedHashMap<FilterConfigType,String>();

  FilterTagsWidget({Key? key, required filterConfigs}) : this._filterConfigs = filterConfigs, super(key: key) {
    if (this._filterConfigs.sortBy.isNotEmpty) {
      this._filterConfigsMap[FilterConfigType.SORTING_RULE] = this._filterConfigs.getSortingRuleDispStr(this._filterConfigs.sortBy);
    }

    if (this._filterConfigs.price > 0) {
      this._filterConfigsMap[FilterConfigType.PRICE] = this._filterConfigs.getPriceDispStr(this._filterConfigs.price);
    }

    if (this._filterConfigs.openAt > 0) {
      this._filterConfigsMap[FilterConfigType.OPEN_AT] = this._filterConfigs.openAtDispStr;
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    child: Center(
      child: Tags(
          key: this._tagStateKey,
          itemCount: this._filterConfigsMap.keys.length,
          itemBuilder: (int index) => ItemTags(
              key: Key(index.toString()),
              index: index,
              title: this._filterConfigsMap.values.toList()[index],
              textStyle: TextStyle( fontSize: Dimens.xhFontSize),
              customData: this._filterConfigsMap.keys.toList()[index],
              combine: ItemTagsCombine.withTextBefore,
              color: Theme.of(context).primaryColor,
              onPressed: (item) {
                debugPrint('item = ${item}');
                context.findAncestorStateOfType<MainPageState>()?.setState(() {
                  this._filterConfigs.clearConfig(item.customData as FilterConfigType);
                });
              }
          )
      )
    )
  );
}
