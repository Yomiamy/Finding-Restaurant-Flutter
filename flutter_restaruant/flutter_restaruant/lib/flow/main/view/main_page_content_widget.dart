import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../component/component_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../model/model_barrel.dart';
import '../bloc/bloc_barrel.dart';
import 'map_widget.dart';
import 'restaurant_info_list_widget.dart';

/// 主頁面的內容呈現元件。
///
/// 負責呈現載入骨架屏、查無資料空畫面、餐廳列表或地圖模式，
/// 並在 [ResetSuccess] 時自動調用 [FetchSearchInfo] 更新資料。
class MainPageContentWidget extends StatefulWidget {
  const MainPageContentWidget({
    super.key,
    required this.filterConfigs,
    required this.isListMode,
  });

  final FilterConfigs filterConfigs;
  final bool isListMode;

  @override
  State<MainPageContentWidget> createState() => _MainPageContentWidgetState();
}

class _MainPageContentWidgetState extends State<MainPageContentWidget> {
  List<RestaurantEntity> _summaryInfos = const [];

  @override
  Widget build(BuildContext context) {
    final mainBloc = BlocProvider.of<MainBloc>(context);

    return BlocConsumer<MainBloc, MainState>(
      listener: (context, state) {
        if (state is ResetSuccess) {
          mainBloc.add(
            FetchSearchInfo(
              price: widget.filterConfigs.price,
              openAt: widget.filterConfigs.openAtInSec,
              sortBy: widget.filterConfigs.sortBy,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is Success) {
          _summaryInfos = state.summaryInfos;
        } else if (state is LoadMoreSuccess) {
          _summaryInfos = state.summaryInfos;
        } else if (state is LoadMoreInProgress) {
          _summaryInfos = state.summaryInfos;
        }

        if (state is InProgress ||
            state is MainInitial ||
            state is ResetSuccess) {
          return widget.isListMode
              ? ListView.builder(
                  itemCount: 10,
                  itemBuilder: (_, __) => const RestaurantItemSkeleton(),
                )
              : const Center(child: LoadingWidget());
        }

        if (_summaryInfos.isEmpty) {
          return EmptyDataWidget.withDefaults();
        }

        // display restaurant list
        return widget.isListMode
            ? RestaurantInfoListWidget(
                _summaryInfos,
                widget.filterConfigs,
                isLoadingMore: state is LoadMoreInProgress,
              )
            : MapWidget(_summaryInfos);
      },
    );
  }
}
