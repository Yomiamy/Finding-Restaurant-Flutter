import 'package:flutter_restaruant/api/dio/DioClient.dart';
import 'package:flutter_restaruant/model/ResultVo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:logger/logger.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/http.dart';

part 'APIClz.g.dart';

@RestApi(baseUrl: Constants.BASE_URL)
abstract class APIClz {
  factory APIClz(Dio dio, {String baseUrl}) = _APIClz;

  @POST("/oauth2/token")
  Future<ResultVo> fetchToken(
      @Header("Content-Type") String contentType,
      @Header("Authorization") String authorization,
      @Field("grant_type") String grantType,
      @Field("client_id") String clientId,
      @Field("client_secret") String clientSecret);


  @POST("/v3/businesses/search")
  @Headers(<String, String>{"Content-Type": "application/json"})
  Future<ResultVo> businessesSearch(@Header("Authorization") String token,
      @Field("term") String term,
      @Field("latitude") String latitude,
      @Field("longitude") String longitude,
      @Field("locale") String locale,
      @Field("limit") String limit,
      @Field("openAt") String openAt,
      @Field("sortBy") String sortBy,
      @Field("price") String price);

  @POST("/v3/businesses")
  @Headers(<String, String>{"Content-Type": "application/json"})
  Future<ResultVo> business(@Header("Authorization") String token,
      @Field("locale") String locale);

  @POST("/v3/businesses/{id}/reviews")
  @Headers(<String, String>{"Content-Type": "application/json"})
  Future<ResultVo> review(@Header("Authorization") String token,
      @Path() String id,
      @Field("locale") String locale);
}

final dioClient = DioClient(
    connectionTimeout: Constants.CONNECTION_TIEMOUT,
    receiveTimeout: Constants.RECEIVE_TIEMOUT);
final apiInstance = APIClz(dioClient.dio);
final logger = Logger();
