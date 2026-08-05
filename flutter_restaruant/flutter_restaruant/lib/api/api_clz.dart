import 'package:dio/dio.dart' hide Headers;
import 'package:flutter/foundation.dart';
import 'package:flutter_inspector_kit/flutter_inspector_kit.dart';
import 'package:logger/logger.dart';
import 'package:retrofit/retrofit.dart';

import '../data_layer/dto/dto_barrel.dart';
import '../di/di_barrel.dart';
import '../features/foundation/constants/constants_barrel.dart';
import 'dio/dio_barrel.dart';

part 'api_clz.g.dart';

@RestApi(baseUrl: Constants.baseUrl)
abstract class APIClz {
  factory APIClz(Dio dio, {String? baseUrl}) = _APIClz;

  @POST('/oauth2/token')
  @FormUrlEncoded()
  Future<String> fetchToken(
    @Field('grant_type') String? grantType,
    @Field('client_id') String? clientId,
    @Field('client_secret') String? clientSecret,
  );

  @GET('/v3/businesses/search')
  Future<YelpSearchDto> businessesSearch({
    @Query('term') String? term,
    @Query('latitude') double? latitude,
    @Query('longitude') double? longitude,
    @Query('locale') String? locale,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('open_at') int? openAt,
    @Query('sort_by') String? sortBy,
    @Query('price') int? price,
  });

  @GET('/v3/businesses/{id}')
  Future<YelpRestaurantDetailDto> business(
    @Path() String? id,
    @Query('locale') String? locale,
  );

  @GET('/v3/businesses/{id}/reviews')
  Future<YelpReviewDto> review(
    @Path() String? id,
    @Query('locale') String? locale,
  );
}

final dioClient = () {
  final client = DioClient(
    connectionTimeout: Constants.connectionTimeout,
    receiveTimeout: Constants.receiveTimeout,
    interceptWraps: [
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          var customHeaders = {
            'Content-Type': 'application/json',
            'Authorization': Constants.authToken,
          };
          options.headers.addAll(customHeaders);
          handler.next(options);
        },
      ),
    ],
  );
  final insp = inspector;
  if (kDebugMode && insp != null) {
    client.dio.interceptors.add(
      FlutterInspectorDioInterceptor(insp, sourceDio: client.dio),
    );
  }
  return client;
}();
final apiInstance = APIClz(dioClient.dio);
final logger = Logger();
