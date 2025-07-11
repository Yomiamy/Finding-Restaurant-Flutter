import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/flow/restaurant/bloc/RestaurantDetailBloc.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class RestaurantHeadCell extends StatelessWidget {
  static const int HEAD_IMAGE_H = 200;

  final String _imageUrl;
  final YelpRestaurantSummaryInfo _summaryInfo;
  late RestaurantDetailBloc _bloc;

  RestaurantHeadCell(
      {Key? key = const Key("RestaurantHeadCell"),
      required String imageUrl,
      required YelpRestaurantSummaryInfo summaryInfo})
      : this._imageUrl = imageUrl,
        this._summaryInfo = summaryInfo,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    this._bloc = BlocProvider.of<RestaurantDetailBloc>(context);

    return Stack(
      children: <Widget>[
        FadeInImage.assetNetwork(
            placeholder: UIConstants.NO_IMAGE,
            imageErrorBuilder: (context, error, trace) =>
                Image.asset(UIConstants.NO_IMAGE),
            image: this._imageUrl,
            imageCacheHeight: RestaurantHeadCell.HEAD_IMAGE_H,
            imageCacheWidth: MediaQuery.of(context).size.width.toInt(),
            placeholderCacheHeight: RestaurantHeadCell.HEAD_IMAGE_H,
            placeholderCacheWidth: MediaQuery.of(context).size.width.toInt(),
            fit: BoxFit.fill,
            width: MediaQuery.of(context).size.width,
            height: RestaurantHeadCell.HEAD_IMAGE_H.toDouble()),
        StatefulBuilder(builder: (context, setState) {
          return GestureDetector(
              onTap: () {
                this._bloc.add(ToggleFavor(summaryInfo: this._summaryInfo));
              },
              child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                      padding: EdgeInsets.only(top: 10, right: 10),
                      child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Image.asset(
                              this._summaryInfo.favor
                                  ? "images/ic_favor_fill.png"
                                  : "images/ic_favor_empty.png",
                              width: UIConstants.FAVOR_IMAGE_W,
                              height: UIConstants.FAVOR_IMAGE_H,
                              fit: BoxFit.fill)))));
        })
      ],
    );
  }
}
