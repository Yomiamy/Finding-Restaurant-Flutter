import 'package:dio/dio.dart';
import '../../features/foundation/constants/constants_barrel.dart';

class DioClient {
  late Dio dio;

  DioClient(
      {int connectionTimeout = Constants.connectionTimeout,
      int receiveTimeout = Constants.receiveTimeout,
      bool isLogEnabled = true,
      List<InterceptorsWrapper>? interceptWraps}) {
    BaseOptions options = () {
      BaseOptions options = BaseOptions();
      options.connectTimeout = Duration(milliseconds: connectionTimeout);
      options.receiveTimeout = Duration(milliseconds: receiveTimeout);

      return options;
    }();

    dio = () {
      Dio dio = Dio(options);

      if (isLogEnabled) {
        dio.interceptors
            .add(LogInterceptor(requestBody: true, responseBody: true));
      }

      if (interceptWraps != null && interceptWraps.isNotEmpty) {
        dio.interceptors.addAll(interceptWraps);
      }

      return dio;
    }();
  }
}
