import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/flow/filter/view/FilterPage.dart';
import 'package:flutter_restaruant/flow/main/bloc/MainBloc.dart';
import 'package:flutter_restaruant/flow/main/repository/MainRepository.dart';
import 'package:flutter_restaruant/flow/main/view/MainPage.dart';
import 'package:flutter_restaruant/flow/restaurant/view/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/flow/restaurant/bloc/RestaurantDetailBloc.dart';
import 'package:flutter_restaruant/flow/restaurant/repository/RestaurantDetailRepository.dart';

Map<String, WidgetBuilder> ROUTES_TABLE = <String, WidgetBuilder> {
  MainPage.ROUTE_NAME: (context) => BlocProvider<MainBloc>(
      create: (_) => MainBloc(repository: MainRepository()),
      child: MainPage()
  ),
  RestaurantDetailPage.ROUTE_NAME: (context) => BlocProvider<RestaurantDetailBloc>(
      create: (_) => RestaurantDetailBloc(repository: RestaurantDetailRepository()),
      child: RestaurantDetailPage()
  ),
  FilterPage.ROUTE_NAME: (context) => FilterPage()
};