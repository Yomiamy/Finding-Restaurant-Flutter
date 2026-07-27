import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../component/empty_data_widget.dart';
import '../../../component/loading_widget.dart';
import '../../../component/ad/interstitial_ad.dart';
import '../../../component/ad/interstitial_ad_state.dart';
import '../../../component/cell/restaurant_detail/restaurant_detail_cell_collection.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../manager/ad_counter_manager.dart';
import '../../../utils/tuple.dart';
import '../../../utils/ui_constants.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../bloc/restaurant_detail_bloc.dart';
import '../../../generated/l10n.dart';
import '../../../gen/colors.gen.dart';

class RestaurantDetailPage extends StatefulWidget {
  static const routeName = '/RestaurantDetailPage';

  const RestaurantDetailPage({super.key});

  @override
  State<StatefulWidget> createState() => RestaurantDetailPageState();
}

class RestaurantDetailPageState extends State<RestaurantDetailPage> {
  late RestaurantEntity _summaryInfo;
  late RestaurantDetailBloc _bloc;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)!.settings.arguments
          as Tuple2<RestaurantEntity, dynamic>;
      _summaryInfo = args.item1;
      _bloc.add(FetchDetailInfo(id: _summaryInfo.id!));
      _isInit = true;
    }
  }

  @override
  void initState() {
    super.initState();

    _bloc = BlocProvider.of<RestaurantDetailBloc>(context);

    if (AdCounterManager().decrementAndCheckShouldShowAd()) {
      // iOS DetailPage才有全屏AD
      IntersitialAD(adState: InterstitialADState()).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                padding: const EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: ColorName.backBtnColor)),
            title: BlocBuilder<RestaurantDetailBloc, RestaurantDetailState>(
                bloc: _bloc,
                builder: (context, state) {
                  if (state is Success) {
                    return Text(state.detailInfo.name ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: UIConstants.xxxhFontSize));
                  } else {
                    return const Text('');
                  }
                }),
            backgroundColor: ColorName.appPrimaryColor),
        body: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BlocConsumer<RestaurantDetailBloc, RestaurantDetailState>(
                bloc: _bloc,
                listener: (context, state) {
                  if (state is ToggleFavorSuccess) {
                    // The repository persists a copyWith() result instead of
                    // mutating _summaryInfo, so adopt the new value here.
                    // RestaurantHeadCell reads _summaryInfo.favor for the
                    // heart icon, which would otherwise stay stale.
                    setState(() {
                      _summaryInfo =
                          _summaryInfo.copyWith(favor: !_summaryInfo.favor);
                    });

                    String favorToggleMsg = _summaryInfo.favor
                        ? S.current.favorite_store_add
                        : S.current.favorite_store_remove;

                    Fluttertoast.showToast(msg: favorToggleMsg);
                    // Re-fetch detail and build detail page
                    _bloc.add(FetchDetailInfo(id: _summaryInfo.id!));
                  }
                },
                builder: (context, state) {
                  if (state is InProgress || state is ToggleFavorSuccess) {
                    return const Center(child: LoadingWidget());
                  } else if (state is Success) {
                    return ListView(children: [
                      RestaurantHeadCell(
                          imageUrl: state.detailInfo.imageUrl ?? '',
                          summaryInfo: _summaryInfo),
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
                    return const EmptyDataWidget();
                  }
                })));
  }
}
