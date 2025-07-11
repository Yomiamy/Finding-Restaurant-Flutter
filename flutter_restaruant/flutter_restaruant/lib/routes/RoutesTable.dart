import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/flow/favor/bloc/FavorBloc.dart';
import 'package:flutter_restaruant/flow/favor/repository/FavorRepository.dart';
import 'package:flutter_restaruant/flow/favor/view/FavorPage.dart';
import 'package:flutter_restaruant/flow/photoviewr/view/PhotoViewer.dart';
import 'package:flutter_restaruant/flow/filter/view/FilterPage.dart';
import 'package:flutter_restaruant/flow/main/bloc/MainBloc.dart';
import 'package:flutter_restaruant/flow/main/repository/MainRepository.dart';
import 'package:flutter_restaruant/flow/main/view/MainPage.dart';
import 'package:flutter_restaruant/flow/restaurant/view/RestaurantDetailPage.dart';
import 'package:flutter_restaruant/flow/restaurant/bloc/RestaurantDetailBloc.dart';
import 'package:flutter_restaruant/flow/restaurant/repository/RestaurantDetailRepository.dart';
import 'package:flutter_restaruant/flow/settings/bloc/SettingsBloc.dart';
import 'package:flutter_restaruant/flow/settings/repository/SettingsRepository.dart';
import 'package:flutter_restaruant/flow/settings/view/SettingsPage.dart';
import 'package:flutter_restaruant/flow/signinup/bloc/SignInBloc.dart';
import 'package:flutter_restaruant/flow/signinup/repository/SignInRepository.dart';
import 'package:flutter_restaruant/flow/signinup/view/SignInPage.dart';
import 'package:flutter_restaruant/flow/splash/view/SplashPage.dart';

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
