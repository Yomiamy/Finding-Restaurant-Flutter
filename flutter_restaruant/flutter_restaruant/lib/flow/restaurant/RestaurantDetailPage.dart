import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/cell/restaurant_detail/RestaurantDetailCellCollection.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class RestaurantDetailPage extends StatefulWidget {

  final YelpRestaurantDetailInfo detailInfo;

  const RestaurantDetailPage({required this.detailInfo});

  @override
  State<StatefulWidget> createState() => RestaurantDetailState();
}

class RestaurantDetailState extends State<RestaurantDetailPage> {

  @override
  Widget build(BuildContext context) => PlatformScaffold(
      appBar: PlatformAppBar(
          leading: PlatformIconButton(
              padding: EdgeInsets.all(0),
              onPressed: () => Navigator.of(context).pop(),
              materialIcon: Icon(Icons.arrow_back,
                  color: Color(UIConstants.BackBtnColor)),
              cupertinoIcon: Icon(CupertinoIcons.back,
                  color: Color(UIConstants.BackBtnColor))),
          title: Text(widget.detailInfo.name ?? "",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Color(UIConstants.AppBarColor)),
      body: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: ListView(children: [
          RestaurantHeadCell(imageUrl: widget.detailInfo.image_url ?? ""),
          RestaurantInfoCell(),
          RestaurantImageCell(imageUrl: widget.detailInfo.image_url ?? ""),
          RestaurantBusinessCell(),
          RestaurantCommentCell()
        ])
      ));
}
