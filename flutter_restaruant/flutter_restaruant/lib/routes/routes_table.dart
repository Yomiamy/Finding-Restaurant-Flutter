import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/flow/favor/bloc/favor_bloc.dart';
import 'package:flutter_restaruant/flow/favor/repository/favor_repository.dart';
import 'package:flutter_restaruant/flow/favor/view/favor_page.dart';
import 'package:flutter_restaruant/flow/photoviewr/view/photo_viewer.dart';
import 'package:flutter_restaruant/flow/filter/view/filter_page.dart';
import 'package:flutter_restaruant/flow/main/bloc/main_bloc.dart';
import 'package:flutter_restaruant/flow/main/repository/main_repository.dart';
import 'package:flutter_restaruant/flow/main/view/main_page.dart';
import 'package:flutter_restaruant/flow/restaurant/view/restaurant_detail_page.dart';
import 'package:flutter_restaruant/flow/restaurant/bloc/restaurant_detail_bloc.dart';
import 'package:flutter_restaruant/flow/restaurant/repository/restaurant_detail_repository.dart';
import 'package:flutter_restaruant/flow/settings/bloc/settings_bloc.dart';
import 'package:flutter_restaruant/flow/settings/repository/settings_repository.dart';
import 'package:flutter_restaruant/flow/settings/view/settings_page.dart';
import 'package:flutter_restaruant/flow/signinup/bloc/sign_in_bloc.dart';
import 'package:flutter_restaruant/flow/signinup/repository/sign_in_repository.dart';
import 'package:flutter_restaruant/flow/signinup/view/sign_in_page.dart';
import 'package:flutter_restaruant/flow/splash/view/splash_page.dart';

Map<String, WidgetBuilder> ROUTES_TABLE = <String, WidgetBuilder>{
  SplashPage.ROUTE_NAME: (context) => SplashPage(),
  SignInPage.ROUTE_NAME: (context) => BlocProvider<SignInBloc>(
      create: (_) => SignInBloc(repository: SignInRepository()),
      child: SignInPage()),
  MainPage.ROUTE_NAME: (context) => BlocProvider<MainBloc>(
      create: (_) => MainBloc(repository: MainRepository()), child: MainPage()),
  RestaurantDetailPage.ROUTE_NAME: (context) =>
      BlocProvider<RestaurantDetailBloc>(
          create: (_) =>
              RestaurantDetailBloc(repository: RestaurantDetailRepository()),
          child: RestaurantDetailPage()),
  FavorPage.ROUTE_NAME: (context) => BlocProvider<FavorBloc>(
      create: (_) => FavorBloc(repository: FavorRepository()),
      child: FavorPage()),
  FilterPage.ROUTE_NAME: (context) => FilterPage(),
  PhotoViewer.ROUTE_NAME: (context) => PhotoViewer(),
  SettingsPage.ROUTE_NAME: (context) => BlocProvider<SettingsBloc>(
      create: (_) => SettingsBloc(repository: const SettingsRepository()),
      child: SettingsPage())
};
