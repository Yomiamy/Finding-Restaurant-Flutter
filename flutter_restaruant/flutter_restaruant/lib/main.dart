import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/flow/main/bloc/MainBloc.dart';
import 'package:flutter_restaruant/flow/main/repository/MainRepository.dart';
import 'package:flutter_restaruant/flow/splash/view/SplashPage.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'firebase_options.dart';
import 'flow/login/view/LoginPage.dart';
import 'flow/main/view/MainPage.dart';
import 'routes/RoutesTable.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(FindingRestaruantApp());
}

class FindingRestaruantApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => PlatformApp(
      title:  Constants.APP_TITLE,
      routes: ROUTES_TABLE
  );
}


