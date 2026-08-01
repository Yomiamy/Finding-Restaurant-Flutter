import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../domain/repositories/repositories_barrel.dart';
import '../flow/favor/bloc/bloc_barrel.dart';
import '../flow/favor/view/view_barrel.dart';
import '../flow/filter/view/view_barrel.dart';
import '../flow/main/bloc/bloc_barrel.dart';
import '../flow/main/view/view_barrel.dart';
import '../flow/photo_viewer/view/view_barrel.dart';
import '../flow/restaurant/bloc/bloc_barrel.dart';
import '../flow/restaurant/view/view_barrel.dart';
import '../flow/settings/bloc/bloc_barrel.dart';
import '../flow/settings/view/view_barrel.dart';
import '../flow/signinup/bloc/bloc_barrel.dart';
import '../flow/signinup/view/view_barrel.dart';
import '../flow/splash/view/view_barrel.dart';

final Map<String, WidgetBuilder> routesTable = <String, WidgetBuilder>{
  SplashPage.routeName: (context) => const SplashPage(),
  SignInPage.routeName: (context) => BlocProvider<SignInBloc>(
      create: (_) => SignInBloc(repository: GetIt.I<SignInRepository>()),
      child: const SignInPage()),
  MainPage.routeName: (context) => BlocProvider<MainBloc>(
      create: (_) => MainBloc(repository: GetIt.I<MainRepository>()),
      child: const MainPage()),
  RestaurantDetailPage.routeName: (context) =>
      BlocProvider<RestaurantDetailBloc>(
          create: (_) => RestaurantDetailBloc(
              repository: GetIt.I<RestaurantDetailRepository>()),
          child: const RestaurantDetailPage()),
  FavorPage.routeName: (context) => BlocProvider<FavorBloc>(
      create: (_) => FavorBloc(repository: GetIt.I<FavorRepository>()),
      child: const FavorPage()),
  FilterPage.routeName: (context) => const FilterPage(),
  PhotoViewer.routeName: (context) => const PhotoViewer(),
  SettingsPage.routeName: (context) => BlocProvider<SettingsBloc>(
      create: (_) => SettingsBloc(repository: GetIt.I<SettingsRepository>()),
      child: const SettingsPage())
};
