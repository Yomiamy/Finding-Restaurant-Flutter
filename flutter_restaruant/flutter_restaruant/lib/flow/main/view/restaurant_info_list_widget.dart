import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../component/cell/main_page/main_page_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/extension/extension_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../model/model_barrel.dart';
import '../../restaurant/view/view_barrel.dart';
import '../bloc/bloc_barrel.dart';
import 'filter_tags_widget.dart';
import 'main_page.dart';

class RestaurantInfoListWidget extends StatefulWidget {
  final List<RestaurantEntity> _summaryInfos;
  final FilterConfigs _configs;
  final bool _isLoadingMore;

  const RestaurantInfoListWidget(
    this._summaryInfos,
    this._configs, {
    super.key,
    bool isLoadingMore = false,
  }) : _isLoadingMore = isLoadingMore;

  @override
  State<RestaurantInfoListWidget> createState() =>
      _RestaurantInfoListWidgetState();
}

class _RestaurantInfoListWidgetState extends State<RestaurantInfoListWidget> {
  final ScrollController _scrollController = ScrollController();

  List<RestaurantEntity> get _summaryInfos => widget._summaryInfos;
  FilterConfigs get _configs => widget._configs;
  bool get _isLoadingMore => widget._isLoadingMore;

  @override
  void didUpdateWidget(RestaurantInfoListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only react to the moment loading starts.
    if (oldWidget._isLoadingMore || !widget._isLoadingMore) return;

    // The indicator is appended below the current bottom, so the viewport stays
    // pinned where it was and the spinner renders off-screen. Extend the scroll
    // to reveal it once loading starts.
    runAfterFrame(() {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MainBloc mainBloc = BlocProvider.of<MainBloc>(context);

    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        // depth == 0 keeps the horizontal tag scroller in FilterTagsWidget from
        // firing a page fetch when it reaches its own edge. The _isLoadingMore
        // guard stops the reveal animation from re-triggering the same fetch.
        if (notification.depth == 0 &&
            notification.metrics.extentAfter == 0 &&
            !_isLoadingMore) {
          int? price = _configs.price;
          int? openAt = _configs.openAtInSec;
          String? sortBy = _configs.sortBy;

          // Load more when scrolling reach the edge of ListView
          mainBloc.add(
            FetchSearchInfo(price: price, openAt: openAt, sortBy: sortBy),
          );
        }
        return true;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: ThemeSize.zero,
          bottom: ThemeSize.zero,
        ),
        controller: _scrollController,
        itemCount: _summaryInfos.length + 1 + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return FilterTagsWidget(filterConfigs: _configs);
          } else if (index == _summaryInfos.length + 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: ThemeSize.space16),
              child: Center(child: CircularProgressIndicator()),
            );
          } else {
            RestaurantEntity summaryInfo = _summaryInfos[index - 1];

            return GestureDetector(
              child: RestaurantItemCell(summaryInfo: summaryInfo),
              onTap: () async {
                Tuple2 arguments = Tuple2<RestaurantEntity, dynamic>(
                  summaryInfo,
                  null,
                );

                // Avoid duplicate push, use pushNamedAndRemoveUntil instead of push
                // ignore: unawaited_futures
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RestaurantDetailPage.routeName,
                  ModalRoute.withName(MainPage.routeName),
                  arguments: arguments,
                );
              },
            );
          }
        },
      ),
    );
  }
}
