// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'APIClz.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _APIClz implements APIClz {
  _APIClz(this._dio, {this.baseUrl}) {
    baseUrl ??= 'https://api.yelp.com';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<String> fetchToken(grantType, clientId, clientSecret) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = {
      'grant_type': grantType,
      'client_id': clientId,
      'client_secret': clientSecret
    };
    _data.removeWhere((k, v) => v == null);
    final _result = await _dio.fetch<String>(_setStreamType<String>(Options(
            method: 'POST',
            headers: <String, dynamic>{},
            extra: _extra,
            contentType: 'application/x-www-form-urlencoded')
        .compose(_dio.options, '/oauth2/token',
            queryParameters: queryParameters, data: _data)
        .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data!;
    return value;
  }

  @override
  Future<YelpSearchInfo> businessesSearch(
      {term, latitude, longitude, locale, limit, openAt, sortBy, price}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'term': term,
      r'latitude': latitude,
      r'longitude': longitude,
      r'locale': locale,
      r'limit': limit,
      r'openAt': openAt,
      r'sortBy': sortBy,
      r'price': price
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<YelpSearchInfo>(
            Options(method: 'GET', headers: <String, dynamic>{}, extra: _extra)
                .compose(_dio.options, '/v3/businesses/search',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = YelpSearchInfo.fromJson(_result.data!);
    return value;
  }

  @override
  Future<YelpRestaurantDetailInfo> business(locationName, locale) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = {'locale': locale};
    _data.removeWhere((k, v) => v == null);
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<YelpRestaurantDetailInfo>(
            Options(method: 'GET', headers: <String, dynamic>{}, extra: _extra)
                .compose(_dio.options, '/v3/businesses/$locationName',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = YelpRestaurantDetailInfo.fromJson(_result.data!);
    return value;
  }

  @override
  Future<YelpReviewInfo> review(id, locale) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = {'locale': locale};
    _data.removeWhere((k, v) => v == null);
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<YelpReviewInfo>(
            Options(method: 'GET', headers: <String, dynamic>{}, extra: _extra)
                .compose(_dio.options, '/v3/businesses/$id/reviews',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = YelpReviewInfo.fromJson(_result.data!);
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }
}
