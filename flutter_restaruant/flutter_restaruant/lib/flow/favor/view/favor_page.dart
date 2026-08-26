import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../component/component_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../bloc/bloc_barrel.dart';
import '../../restaurant/view/view_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

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
    _favorBloc.add(const FetchFavorInfoEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: ThemeColor.backBtn),
        ),
        title: Text(
          S.current.favorite_stores,
          style: const TextStyle(
            color: Colors.white,
            fontSize: ThemeFontSize.fontSize22,
          ),
        ),
        backgroundColor: ThemeColor.appPrimary,
      ),
      body: BlocBuilder<FavorBloc, FavorState>(
        bloc: _favorBloc,
        builder: (context, state) {
          if (state is InProgress) {
            return ListView.builder(
              itemCount: 10,
              itemBuilder: (_, __) => const RestaurantItemSkeleton(),
            );
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
                    final needRefresh =
                        await Navigator.of(context).pushNamed(
                              RestaurantDetailPage.routeName,
                              arguments: arguments,
                            )
                            as bool?;

                    // 若手勢滑動返回，needRefresh 為 null。為防畫面不一致，遇到 null 也視同需要更新。
                    if (needRefresh ?? true) {
                      _favorBloc.add(const FetchFavorInfoEvent());
                    }
                  },
                );
              },
            );
          } else {
            return EmptyDataWidget.withDefaults();
          }
        },
      ),
    );
  }
}
