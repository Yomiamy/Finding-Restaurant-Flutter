import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/flow/filter/view/FilterPage.dart';
import 'package:flutter_restaruant/flow/restaurant/view/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/flow/restaurant/bloc/RestaurantDetailBloc.dart';
import 'package:flutter_restaruant/flow/restaurant/repository/RestaurantDetailRepository.dart';

Map<String, WidgetBuilder> ROUTES_TABLE = <String, WidgetBuilder> {
  RestaurantDetailPage.ROUTE_NAME: (context) => BlocProvider<RestaurantDetailBloc>(
      create: (_) => RestaurantDetailBloc(repository: RestaurantDetailRepository()),
      child: RestaurantDetailPage()
  ),
  FilterPage.ROUTE_NAME: (context) => FilterPage()
};