import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'SplashEvent.dart';
part 'SplashState.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {

  SplashBloc() : super(SplashInitial());
}
