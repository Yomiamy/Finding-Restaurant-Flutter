import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../flow/restaurant/bloc/restaurant_detail_bloc.dart';
import '../../../flow/signinup/view/sign_in_page.dart';
import '../../../manager/sign_in_manager.dart';
import '../../../features/foundation/style/style.dart';
import '../../../features/foundation/constants/app_constants.dart';

class RestaurantHeadCell extends StatelessWidget {
  static const int headImageH = 200;

  final String _imageUrl;
  final RestaurantEntity _summaryInfo;
  const RestaurantHeadCell(
      {super.key = const Key('RestaurantHeadCell'),
      required String imageUrl,
      required RestaurantEntity summaryInfo})
      : _imageUrl = imageUrl,
        _summaryInfo = summaryInfo;

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<RestaurantDetailBloc>(context);

    return Stack(
      children: <Widget>[
        FadeInImage.assetNetwork(
            placeholder: UIConstants.noImage,
            imageErrorBuilder: (context, error, trace) =>
                Image.asset(UIConstants.noImage),
            image: _imageUrl,
            imageCacheHeight: RestaurantHeadCell.headImageH,
            imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
            placeholderCacheHeight: RestaurantHeadCell.headImageH,
            placeholderCacheWidth: MediaQuery.of(context).size.width.toInt(),
            fit: BoxFit.fill,
            width: MediaQuery.of(context).size.width,
            height: RestaurantHeadCell.headImageH.toDouble()),
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
                        top: Sizes.space10, right: Sizes.space10),
                    child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Image.asset(
                            _summaryInfo.favor
                                ? 'images/ic_favor_fill.png'
                                : 'images/ic_favor_empty.png',
                            width: Sizes.favorImageW,
                            height: Sizes.favorImageH,
                            fit: BoxFit.fill)))))
      ],
    );
  }
}
