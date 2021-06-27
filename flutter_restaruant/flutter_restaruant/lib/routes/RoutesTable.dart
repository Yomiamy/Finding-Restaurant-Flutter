import 'package:flutter/material.dart';
import 'package:flutter_restaruant/flow/restaurant/RestaurantDetailPage.dart';

Map<String, WidgetBuilder> ROUTES_TABLE = <String, WidgetBuilder> {
  RestaurantDetailPage.ROUTE_NAME: (context) => RestaurantDetailPage()
};