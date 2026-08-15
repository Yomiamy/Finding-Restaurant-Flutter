import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../../component/component_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../bloc/bloc_barrel.dart';
import '../../restaurant/view/view_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';

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
          padding: const EdgeInsets.all(ThemeSize.zero),
          onPressed: () => Navigator.of(context).pop(),
          materialIcon: const Icon(Icons.arrow_back, color: ThemeColor.backBtn),
          cupertinoIcon: const Icon(
            CupertinoIcons.back,
            color: ThemeColor.backBtn,
          ),
        ),
        title: const Text(
          UIConstants.favorTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: UIConstants.xxxxhFontSize,
          ),
        ),
        backgroundColor: ThemeColor.appPrimary,
      ),
      body: BlocBuilder<FavorBloc, FavorState>(
        bloc: _favorBloc,
        builder: (context, state) {
          if (state is InProgress) {
            return const Center(child: LoadingWidget());
          } else if (state is Success) {
            List<RestaurantEntity> favorInfos = state.favorInfos;

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: ThemeSize.zero,
                bottom: ThemeSize.zero,
              ),
              itemCount: favorInfos.length,
              itemBuilder: (context, index) {
                RestaurantEntity favorInfo = favorInfos[index];

                return GestureDetector(
                  child: RestaurantItemCell(summaryInfo: favorInfo),
                  onTap: () async {
                    Tuple2 arguments = Tuple2<RestaurantEntity, dynamic>(
                      favorInfo,
                      null,
                    );
                    await Navigator.of(context).pushNamed(
                      RestaurantDetailPage.routeName,
                      arguments: arguments,
                    );

                    _favorBloc.add(const FetchFavorInfoEvent(true));
                  },
                );
              },
            );
          } else {
            return const EmptyDataWidget();
          }
        },
      ),
    );
  }
}
