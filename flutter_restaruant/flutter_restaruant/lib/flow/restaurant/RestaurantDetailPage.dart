import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/cell/restaurant_detail/RestaurantDetailCellCollection.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class RestaurantDetailPage extends StatefulWidget {

  static const ROUTE_NAME = "RestaurantDetailPage";

  const RestaurantDetailPage();

  @override
  State<StatefulWidget> createState() => RestaurantDetailState();
}

class RestaurantDetailState extends State<RestaurantDetailPage> {

  late YelpRestaurantDetailInfo detailInfo;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Tuple2<YelpRestaurantDetailInfo, dynamic>;
    this.detailInfo = args.item1;

    return PlatformScaffold(
        appBar: PlatformAppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: Color(UIConstants.BackBtnColor)),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: Color(UIConstants.BackBtnColor))),
            title: Text(this.detailInfo.name ?? "",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Color(UIConstants.AppBarColor)),
        body: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: ListView(children: [
              RestaurantHeadCell(imageUrl: this.detailInfo.image_url ?? ""),
              RestaurantInfoCell(),
              RestaurantImageCell(imageUrl: this.detailInfo.image_url ?? ""),
              RestaurantBusinessCell(),
              RestaurantCommentCell()
            ])));
  }
}
