import 'package:dio/dio.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class DioClient {

   late Dio dio;

   DioClient({int connectionTimeout = Constants.CONNECTION_TIEMOUT,
         int receiveTimeout = Constants.RECEIVE_TIEMOUT,
         bool isLogEnabled = true,
         List<InterceptorsWrapper>? interceptWraps}) {
     BaseOptions options = () {
      BaseOptions options = BaseOptions();
      options.connectTimeout = Duration(milliseconds: connectionTimeout);
      options.receiveTimeout = Duration(milliseconds: receiveTimeout);

      return options;
    }();

    this.dio = () {
      Dio dio = Dio(options);

      if (isLogEnabled) {
        dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
      }

      if(interceptWraps != null && interceptWraps.isNotEmpty) {
        dio.interceptors.addAll(interceptWraps);
      }

      return dio;
    } ();
   }
}