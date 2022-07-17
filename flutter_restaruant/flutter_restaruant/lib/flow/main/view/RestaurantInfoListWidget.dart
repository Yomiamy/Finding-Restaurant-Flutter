import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/component/ad/BannerAD.dart';
import 'package:flutter_restaruant/component/ad/BannerADState.dart';
import 'package:flutter_restaruant/component/cell/main_page/RestaurantItemCell.dart';
import 'package:flutter_restaruant/flow/main/bloc/MainBloc.dart';
import 'package:flutter_restaruant/flow/main/view/FilterTagsWidget.dart';
import 'package:flutter_restaruant/flow/main/view/MainPage.dart';
import 'package:flutter_restaruant/flow/restaurant/view/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/model/FilterConfigs.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:provider/provider.dart';

class RestaurantInfoListWidget extends StatelessWidget {

  ScrollController _scrollController = ScrollController();
  List<YelpRestaurantSummaryInfo> _summaryInfos;
  FilterConfigs _configs;

  RestaurantInfoListWidget(this._summaryInfos, this._configs);

  @override
  Widget build(BuildContext context) {
    MainBloc mainBloc = BlocProvider.of<MainBloc>(context);

    return NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          if(this._scrollController.position.atEdge) {
            int? price = this._configs.price;
            int? openAt = this._configs.openAtInSec;
            String? sortBy = this._configs.sortBy;

            // Load more when scrolling reach the edge of ListView
            mainBloc.add(FetchSearchInfo(price: price, openAt: openAt, sortBy: sortBy));
          }
          return true;
        },
        child: ListView.builder(
            padding: EdgeInsets.only(top: 0, bottom: 0),
            controller: this._scrollController,
            itemCount: this._summaryInfos.length + 2 ,
            itemBuilder: (context, index) {
              if(index == 0) {
                final adState = Provider.of<BannerADState>(context);

                return BannerAD(adState: adState);
              } else if(index == 1) {
                return FilterTagsWidget(filterConfigs: this._configs);
              } else {
                YelpRestaurantSummaryInfo summaryInfo = this._summaryInfos[index - 2];

                return GestureDetector(
                    child: RestaurantItemCell(summaryInfo: summaryInfo),
                    onTap: () async {
                      Tuple2 arguments = Tuple2<YelpRestaurantSummaryInfo, dynamic>(summaryInfo, null);

                      // Avoid duplicate push, use pushNamedAndRemoveUntil instead of push
                      Navigator.of(context).pushNamedAndRemoveUntil(RestaurantDetailPage.ROUTE_NAME, ModalRoute.withName(MainPage.ROUTE_NAME), arguments: arguments);
                    });
              }
            })
    );
  }
}
