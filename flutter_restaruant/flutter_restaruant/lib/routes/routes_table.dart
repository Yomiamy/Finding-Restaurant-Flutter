import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../domain/repositories/favor_repository.dart';
import '../domain/repositories/main_repository.dart';
import '../domain/repositories/restaurant_detail_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/sign_in_repository.dart';
import '../flow/favor/bloc/favor_bloc.dart';
import '../flow/favor/view/favor_page.dart';
import '../flow/filter/view/filter_page.dart';
import '../flow/main/bloc/main_bloc.dart';
import '../flow/main/view/main_page.dart';
import '../flow/photoviewr/view/photo_viewer.dart';
import '../flow/restaurant/bloc/restaurant_detail_bloc.dart';
import '../flow/restaurant/view/restaurant_detail_page.dart';
import '../flow/settings/bloc/settings_bloc.dart';
import '../flow/settings/view/settings_page.dart';
import '../flow/signinup/bloc/sign_in_bloc.dart';
import '../flow/signinup/view/sign_in_page.dart';
import '../flow/splash/view/splash_page.dart';

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
      create: (_) =>
          SettingsBloc(repository: GetIt.I<SettingsRepository>()),
      child: const SettingsPage())
};
