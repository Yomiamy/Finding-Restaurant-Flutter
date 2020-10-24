import 'package:flutter_restaruant/api/dio/DioClient.dart';
import 'package:flutter_restaruant/model/ResultVo.dart';
import 'package:logger/logger.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'APIClz.g.dart';

@RestApi(baseUrl: "http://192.168.6.200:31199/")
abstract class APIClz {
  factory APIClz(Dio dio, {String baseUrl}) = _APIClz;

  @POST("/v1/login")
  Future<ResultVo> login(@Field() String account,@Field() String password);
}

final dioClient = DioClient(
    connectionTimeout: Constants.CONNECTION_TIEMOUT,
    receiveTimeout: Constants.RECEIVE_TIEMOUT);
final apiInstance = APIClz(dioClient.dio);
final logger = Logger();
