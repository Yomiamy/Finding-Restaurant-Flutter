import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/EmptyDataWidget.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/flow/favor/bloc/FavorBloc.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class FavorPage extends StatefulWidget {
  static const ROUTE_NAME = "/FavorPage";

  const FavorPage({Key? key}) : super(key: key);

  @override
  _FavorPageState createState() => _FavorPageState();
}

class _FavorPageState extends State<FavorPage> {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Tuple2<String, dynamic>;
    final uid = args.item1;

    FavorBloc bloc = BlocProvider.of<FavorBloc>(context);
    bloc.add(FetchFavorInfoEvent(uid: uid));
    // TODO: 寫到此
    return PlatformScaffold(
        appBar: PlatformAppBar(
          title: Text(UIConstants.FAVOR_TITLE),
        ),
        body: BlocBuilder<FavorBloc, FavorState>(
            bloc: bloc,
            builder: (context, state) {
              if (state is InProgress) {
                return Center(child: LoadingWidget());
              } else if (state is Success) {
                return ListView.builder(
                    padding: EdgeInsets.only(top: 0, bottom: 0),
                    itemBuilder: (context, index) {
                      // TODO: 未完
                      // YelpRestaurantSummaryInfo summaryInfo = summaryInfos[index - 1];
                      //
                      // return GestureDetector(
                      //     child: RestaurantItemCell(summaryInfo: summaryInfo),
                      //     onTap: () {
                      //       String id = summaryInfo.id ?? "";
                      //       Tuple2 arguments = Tuple2<String, dynamic>(id, null);
                      //
                      //       Navigator.of(context).pushNamed(
                      //           RestaurantDetailPage.ROUTE_NAME,
                      //           arguments: arguments
                      //       );
                      //     });
                      return UIConstants.EmptyWidget;
                    });
              } else {
                return EmptyDataWidget();
              }
            }));
  }
}
