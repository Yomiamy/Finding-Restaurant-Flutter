import 'package:flutter_restaruant/api/dio/DioClient.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/model/YelpReviewInfo.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:logger/logger.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/http.dart';

part 'APIClz.g.dart';

@RestApi(baseUrl: Constants.BASE_URL)
abstract class APIClz {
  factory APIClz(Dio dio, {String? baseUrl}) = _APIClz;

  @POST("/oauth2/token")
  @FormUrlEncoded()
  Future<String> fetchToken(
      @Field("grant_type") String? grantType,
      @Field("client_id") String? clientId,
      @Field("client_secret") String? clientSecret);

  @POST("/v3/businesses/search")
  Future<YelpSearchInfo> businessesSearch(
      @Field("term") String? term,
      @Field("latitude") String? latitude,
      @Field("longitude") String? longitude,
      @Field("locale") String? locale,
      @Field("limit") String? limit,
      {@Field("openAt") String? openAt,
      @Field("sortBy") String? sortBy,
      @Field("price") String? price});

  @GET("/v3/businesses/{locationName}")
  Future<YelpRestaurantDetailInfo> business(
      @Path() String? locationName,
      @Field("locale") String? locale);

  @GET("/v3/businesses/{id}/reviews")
  Future<YelpReviewInfo> review(@Path() String? id,
      @Field("locale") String? locale);
}

final dioClient = DioClient(
    connectionTimeout: Constants.CONNECTION_TIEMOUT,
    receiveTimeout: Constants.RECEIVE_TIEMOUT,
    interceptWraps: [
      InterceptorsWrapper(onRequest: (options, handler) async {
        var customHeaders = {
          "Content-Type": "application/json",
          "Authorization": Constants.AUTH_TOKEN
        };
        options.headers.addAll(customHeaders);
        handler.next(options);
      })
    ]);
final apiInstance = APIClz(dioClient.dio);
final logger = Logger();
