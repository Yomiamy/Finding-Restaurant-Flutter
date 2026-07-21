import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/component/ad/banner_ad.dart';
import 'package:flutter_restaruant/component/ad/banner_ad_state.dart';
import 'package:flutter_restaruant/component/cell/main_page/restaurant_item_cell.dart';
import 'package:flutter_restaruant/flow/main/bloc/main_bloc.dart';
import 'package:flutter_restaruant/flow/main/view/filter_tags_widget.dart';
import 'package:flutter_restaruant/flow/main/view/main_page.dart';
import 'package:flutter_restaruant/flow/restaurant/view/restaurant_detail_page.dart';
import 'package:flutter_restaruant/model/filter_configs.dart';
import 'package:flutter_restaruant/model/yelp_restaurant_summary_info.dart';
import 'package:flutter_restaruant/utils/tuple.dart';
import 'package:provider/provider.dart';

class RestaurantInfoListWidget extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();
  final List<YelpRestaurantSummaryInfo> _summaryInfos;
  final FilterConfigs _configs;

  RestaurantInfoListWidget(this._summaryInfos, this._configs, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    MainBloc mainBloc = BlocProvider.of<MainBloc>(context);

    return NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          if (this._scrollController.position.atEdge) {
            int? price = this._configs.price;
            int? openAt = this._configs.openAtInSec;
            String? sortBy = this._configs.sortBy;

            // Load more when scrolling reach the edge of ListView
            mainBloc.add(
                FetchSearchInfo(price: price, openAt: openAt, sortBy: sortBy));
          }
          return true;
        },
        child: ListView.builder(
            padding: EdgeInsets.only(top: 0, bottom: 0),
            controller: this._scrollController,
            itemCount: this._summaryInfos.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                final adState = Provider.of<BannerADState>(context);

                return BannerAD(adState: adState);
              } else if (index == 1) {
                return FilterTagsWidget(filterConfigs: this._configs);
              } else {
                YelpRestaurantSummaryInfo summaryInfo =
                    this._summaryInfos[index - 2];

                return GestureDetector(
                    child: RestaurantItemCell(summaryInfo: summaryInfo),
                    onTap: () async {
                      Tuple2 arguments =
                          Tuple2<YelpRestaurantSummaryInfo, dynamic>(
                              summaryInfo, null);

                      // Avoid duplicate push, use pushNamedAndRemoveUntil instead of push
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          RestaurantDetailPage.ROUTE_NAME,
                          ModalRoute.withName(MainPage.ROUTE_NAME),
                          arguments: arguments);
                    });
              }
            }));
  }
}
