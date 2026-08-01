import 'dio/dio_client.dart';
import '../data_layer/dto/yelp_restaurant_detail_dto.dart';
import '../data_layer/dto/yelp_review_dto.dart';
import '../data_layer/dto/yelp_search_dto.dart';
import '../features/foundation/constants/app_constants.dart';
import 'package:logger/logger.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart' hide Headers;

part 'api_clz.g.dart';

@RestApi(baseUrl: Constants.baseUrl)
abstract class APIClz {
  factory APIClz(Dio dio, {String? baseUrl}) = _APIClz;

  @POST('/oauth2/token')
  @FormUrlEncoded()
  Future<String> fetchToken(
      @Field('grant_type') String? grantType,
      @Field('client_id') String? clientId,
      @Field('client_secret') String? clientSecret);

  @GET('/v3/businesses/search')
  Future<YelpSearchDto> businessesSearch(
      {@Query('term') String? term,
      @Query('latitude') double? latitude,
      @Query('longitude') double? longitude,
      @Query('locale') String? locale,
      @Query('limit') int? limit,
      @Query('offset') int? offset,
      @Query('open_at') int? openAt,
      @Query('sort_by') String? sortBy,
      @Query('price') int? price});

  @GET('/v3/businesses/{id}')
  Future<YelpRestaurantDetailDto> business(
      @Path() String? id, @Query('locale') String? locale);

  @GET('/v3/businesses/{id}/reviews')
  Future<YelpReviewDto> review(
      @Path() String? id, @Query('locale') String? locale);
}

final dioClient = DioClient(
    connectionTimeout: Constants.connectionTimeout,
    receiveTimeout: Constants.receiveTimeout,
    interceptWraps: [
      InterceptorsWrapper(onRequest: (options, handler) async {
        var customHeaders = {
          'Content-Type': 'application/json',
          'Authorization': Constants.authToken
        };
        options.headers.addAll(customHeaders);
        handler.next(options);
      })
    ]);
final apiInstance = APIClz(dioClient.dio);
final logger = Logger();
