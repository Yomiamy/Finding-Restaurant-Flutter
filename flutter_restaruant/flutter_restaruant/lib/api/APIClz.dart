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

  @GET("/v3/businesses/search")
  Future<YelpSearchInfo> businessesSearch({
      @Query("term") String? term,
      @Query("latitude") double? latitude,
      @Query("longitude") double? longitude,
      @Query("locale") String? locale,
      @Query("limit") int? limit,
      @Query("openAt") int? openAt,
      @Query("sortBy") String? sortBy,
      @Query("price") String? price});

  @GET("/v3/businesses/{locationName}")
  Future<YelpRestaurantDetailInfo> business(
      @Path() String? id,
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
