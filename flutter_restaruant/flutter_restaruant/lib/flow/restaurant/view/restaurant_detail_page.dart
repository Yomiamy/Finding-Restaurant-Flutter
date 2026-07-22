import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/empty_data_widget.dart';
import 'package:flutter_restaruant/component/loading_widget.dart';
import 'package:flutter_restaruant/component/ad/interstitial_ad.dart';
import 'package:flutter_restaruant/component/ad/interstitial_ad_state.dart';
import 'package:flutter_restaruant/component/cell/restaurant_detail/restaurant_detail_cell_collection.dart';
import 'package:flutter_restaruant/model/yelp_restaurant_summary_info.dart';
import 'package:flutter_restaruant/utils/tuple.dart';
import 'package:flutter_restaruant/utils/ui_constants.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../bloc/restaurant_detail_bloc.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/gen/colors.gen.dart';

class RestaurantDetailPage extends StatefulWidget {
  static const ROUTE_NAME = "/RestaurantDetailPage";

  const RestaurantDetailPage();

  @override
  State<StatefulWidget> createState() => RestaurantDetailPageState();
}

class RestaurantDetailPageState extends State<RestaurantDetailPage> {
  late YelpRestaurantSummaryInfo _summaryInfo;
  late RestaurantDetailBloc _bloc;

  @override
  void initState() {
    super.initState();

    this._bloc = BlocProvider.of<RestaurantDetailBloc>(context);

    if (--UIConstants.InterstitialADCountDown <= 0) {
      UIConstants.InterstitialADCountDown = 3;

      // iOS DetailPage才有全屏AD
      IntersitialAD(adState: InterstitialADState()).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments
        as Tuple2<YelpRestaurantSummaryInfo, dynamic>;
    this._summaryInfo = args.item1;

    this._bloc.add(FetchDetailInfo(id: this._summaryInfo.id!));
    return PlatformScaffold(
        appBar: PlatformAppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: ColorName.backBtnColor),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: ColorName.backBtnColor)),
            title: BlocBuilder<RestaurantDetailBloc, RestaurantDetailState>(
                bloc: this._bloc,
                builder: (context, state) {
                  if (state is Success) {
                    return Text(state.detailInfo.name ?? "",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: UIConstants.xxxhFontSize));
                  } else {
                    return Text("");
                  }
                }),
            backgroundColor: ColorName.appPrimaryColor),
        body: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: BlocBuilder<RestaurantDetailBloc, RestaurantDetailState>(
                bloc: this._bloc,
                builder: (context, state) {
                  if (state is InProgress || state is ToggleFavorSuccess) {
                    if (state is ToggleFavorSuccess) {
                      String favorToggleMsg = this._summaryInfo.favor
                          ? S.current.favorite_store_add
                          : S.current.favorite_store_remove;

                      Fluttertoast.showToast(msg: favorToggleMsg);
                      // Re-fetch detail and build detail page
                      this
                          ._bloc
                          .add(FetchDetailInfo(id: this._summaryInfo.id!));
                    }
                    return Center(child: LoadingWidget());
                  } else if (state is Success) {
                    return ListView(children: [
                      RestaurantHeadCell(
                          imageUrl: state.detailInfo.image_url ?? "",
                          summaryInfo: this._summaryInfo),
                      RestaurantInfoCell(
                          detailInfo: state.detailInfo,
                          staticMapUrl: state.staticMapUrl),
                      RestaurantImageCell(
                          photos: state.detailInfo.photos ?? []),
                      RestaurantBusinessHourCell(
                          businessTimeInfos:
                              state.detailInfo.hours?[0].open ?? []),
                      RestaurantCommentCell(
                          reviewInfos: state.reviewInfo.reviews ?? [])
                    ]);
                  } else {
                    return EmptyDataWidget();
                  }
                })));
  }
}
