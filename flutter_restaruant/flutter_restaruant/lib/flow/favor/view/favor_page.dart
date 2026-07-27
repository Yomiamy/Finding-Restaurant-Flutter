import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../../component/empty_data_widget.dart';
import '../../../component/loading_widget.dart';
import '../../../component/cell/main_page/restaurant_item_cell.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../bloc/favor_bloc.dart';
import '../../restaurant/view/restaurant_detail_page.dart';
import '../../../utils/tuple.dart';
import '../../../utils/ui_constants.dart';
import '../../../gen/colors.gen.dart';

class FavorPage extends StatefulWidget {
  static const routeName = '/FavorPage';

  const FavorPage({super.key});

  @override
  State<FavorPage> createState() => _FavorPageState();
}

class _FavorPageState extends State<FavorPage> {
  late FavorBloc _favorBloc;

  @override
  void initState() {
    super.initState();

    _favorBloc = BlocProvider.of<FavorBloc>(context);
    _favorBloc.add(const FetchFavorInfoEvent(false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: PlatformIconButton(
                padding: const EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon:
                    const Icon(Icons.arrow_back, color: ColorName.backBtnColor),
                cupertinoIcon:
                    const Icon(CupertinoIcons.back, color: ColorName.backBtnColor)),
            title: const Text(UIConstants.favorTitle,
                style: TextStyle(
                    color: Colors.white, fontSize: UIConstants.xxxxhFontSize)),
            backgroundColor: ColorName.appPrimaryColor),
        body: BlocBuilder<FavorBloc, FavorState>(
            bloc: _favorBloc,
            builder: (context, state) {
              if (state is InProgress) {
                return const Center(child: LoadingWidget());
              } else if (state is Success) {
                List<RestaurantEntity> favorInfos = state.favorInfos;

                return ListView.builder(
                    padding: const EdgeInsets.only(top: 0, bottom: 0),
                    itemCount: favorInfos.length,
                    itemBuilder: (context, index) {
                      RestaurantEntity favorInfo = favorInfos[index];

                      return GestureDetector(
                          child: RestaurantItemCell(summaryInfo: favorInfo),
                          onTap: () async {
                            Tuple2 arguments =
                                Tuple2<RestaurantEntity, dynamic>(
                                    favorInfo, null);
                            await Navigator.of(context).pushNamed(
                                RestaurantDetailPage.routeName,
                                arguments: arguments);

                            _favorBloc.add(const FetchFavorInfoEvent(true));
                          });
                    });
              } else {
                return const EmptyDataWidget();
              }
            }));
  }
}
