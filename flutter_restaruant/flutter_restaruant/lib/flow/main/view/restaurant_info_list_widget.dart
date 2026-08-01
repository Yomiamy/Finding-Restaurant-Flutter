import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../component/ad/banner_ad.dart';
import '../../../component/ad/banner_ad_state.dart';
import '../../../component/cell/main_page/restaurant_item_cell.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../bloc/main_bloc.dart';
import 'filter_tags_widget.dart';
import 'main_page.dart';
import '../../restaurant/view/restaurant_detail_page.dart';
import '../../../model/filter_configs.dart';
import '../../../features/foundation/style/style.dart';
import '../../../features/utils/app_utils.dart';
import '../../../di/injection.dart';

class RestaurantInfoListWidget extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();
  final List<RestaurantEntity> _summaryInfos;
  final FilterConfigs _configs;

  RestaurantInfoListWidget(this._summaryInfos, this._configs, {super.key});

  @override
  Widget build(BuildContext context) {
    MainBloc mainBloc = BlocProvider.of<MainBloc>(context);

    return NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          if (_scrollController.position.atEdge) {
            int? price = _configs.price;
            int? openAt = _configs.openAtInSec;
            String? sortBy = _configs.sortBy;

            // Load more when scrolling reach the edge of ListView
            mainBloc.add(
                FetchSearchInfo(price: price, openAt: openAt, sortBy: sortBy));
          }
          return true;
        },
        child: ListView.builder(
            padding: const EdgeInsets.only(top: Sizes.zero, bottom: Sizes.zero),
            controller: _scrollController,
            itemCount: _summaryInfos.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return BannerAD(adState: getIt<BannerADState>());
              } else if (index == 1) {
                return FilterTagsWidget(filterConfigs: _configs);
              } else {
                RestaurantEntity summaryInfo = _summaryInfos[index - 2];

                return GestureDetector(
                    child: RestaurantItemCell(summaryInfo: summaryInfo),
                    onTap: () async {
                      Tuple2 arguments =
                          Tuple2<RestaurantEntity, dynamic>(summaryInfo, null);

                      // Avoid duplicate push, use pushNamedAndRemoveUntil instead of push
                      // ignore: unawaited_futures
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          RestaurantDetailPage.routeName,
                          ModalRoute.withName(MainPage.routeName),
                          arguments: arguments);
                    });
              }
            }));
  }
}
