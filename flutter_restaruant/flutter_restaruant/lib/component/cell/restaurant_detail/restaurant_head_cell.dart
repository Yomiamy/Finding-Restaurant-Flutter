import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../flow/restaurant/bloc/bloc_barrel.dart';
import '../../../flow/signinup/view/view_barrel.dart';
import '../../../manager/manager_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';

class RestaurantHeadCell extends StatelessWidget {
  static const int headImageH = 200;

  final String _imageUrl;
  final RestaurantEntity _summaryInfo;
  const RestaurantHeadCell({
    super.key = const Key('RestaurantHeadCell'),
    required String imageUrl,
    required RestaurantEntity summaryInfo,
  }) : _imageUrl = imageUrl,
       _summaryInfo = summaryInfo;

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<RestaurantDetailBloc>(context);

    return Stack(
      children: <Widget>[
        FadeInImage.assetNetwork(
          placeholder: UIConstants.noImage,
          // FadeInImage 的 width/height 不會傳給 errorBuilder 回傳的 widget，
          // 未約束時會以原圖尺寸撐開外層 Stack，把收藏按鈕推出畫面。
          imageErrorBuilder: (context, error, trace) => Image.asset(
            UIConstants.noImage,
            width: MediaQuery.of(context).size.width,
            height: RestaurantHeadCell.headImageH.toDouble(),
            fit: BoxFit.fill,
          ),
          image: _imageUrl,
          imageCacheHeight: RestaurantHeadCell.headImageH,
          imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
          placeholderCacheHeight: RestaurantHeadCell.headImageH,
          placeholderCacheWidth: MediaQuery.of(context).size.width.toInt(),
          fit: BoxFit.fill,
          width: MediaQuery.of(context).size.width,
          height: RestaurantHeadCell.headImageH.toDouble(),
        ),
        GestureDetector(
          onTap: () {
            if (SignInManager().isGuest) {
              // ignore: unawaited_futures
              Navigator.of(context).pushNamed(SignInPage.routeName);
              return;
            }
            bloc.add(ToggleFavor(summaryInfo: _summaryInfo));
          },
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(
                top: ThemeSize.space10,
                right: ThemeSize.space10,
              ),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Image.asset(
                  _summaryInfo.favor
                      ? 'images/ic_favor_fill.png'
                      : 'images/ic_favor_empty.png',
                  width: ThemeSize.size20,
                  height: ThemeSize.size20,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
