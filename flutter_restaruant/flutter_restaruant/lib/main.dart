import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/flow/main/bloc/MainBloc.dart';
import 'package:flutter_restaruant/flow/main/repository/MainRepository.dart';
import 'flow/main/MainPage.dart';
import 'routes/RoutesTable.dart';

void main() {
  runApp(FindingRestaruantApp());
}

class FindingRestaruantApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => PlatformApp(
      title:  "Find Restaurant",
      routes: ROUTES_TABLE,
      home: BlocProvider<MainBloc>(
          create: (_) => MainBloc(repository: MainRepository()),
          child: MainPage(title: "Find Restaurant")
      )
  );
}


