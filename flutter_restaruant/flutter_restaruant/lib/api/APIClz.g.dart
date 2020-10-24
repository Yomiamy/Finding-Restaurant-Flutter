// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'APIClz.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _APIClz implements APIClz {
  _APIClz(this._dio, {this.baseUrl}) {
    ArgumentError.checkNotNull(_dio, '_dio');
    baseUrl ??= 'https://api.yelp.com';
  }

  final Dio _dio;

  String baseUrl;

  @override
  Future<String> fetchToken(grantType, clientId, clientSecret) async {
    ArgumentError.checkNotNull(grantType, 'grantType');
    ArgumentError.checkNotNull(clientId, 'clientId');
    ArgumentError.checkNotNull(clientSecret, 'clientSecret');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = {
      'grant_type': grantType,
      'client_id': clientId,
      'client_secret': clientSecret
    };
    _data.removeWhere((k, v) => v == null);
    final _result = await _dio.request<String>('/oauth2/token',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'POST',
            headers: <String, dynamic>{},
            extra: _extra,
            contentType: 'application/x-www-form-urlencoded',
            baseUrl: baseUrl),
        data: _data);
    final value = _result.data;
    return value;
  }

  @override
  Future<String> businessesSearch(term, latitude, longitude, locale, limit,
      {openAt, sortBy, price}) async {
    ArgumentError.checkNotNull(term, 'term');
    ArgumentError.checkNotNull(latitude, 'latitude');
    ArgumentError.checkNotNull(longitude, 'longitude');
    ArgumentError.checkNotNull(locale, 'locale');
    ArgumentError.checkNotNull(limit, 'limit');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    final _data = {
      'term': term,
      'latitude': latitude,
      'longitude': longitude,
      'locale': locale,
      'limit': limit,
      'openAt': openAt,
      'sortBy': sortBy,
      'price': price
    };
    _data.removeWhere((k, v) => v == null);
    final _result = await _dio.request<String>('/v3/businesses/search',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'POST',
            headers: <String, dynamic>{
              r'Content-Type': 'application/json',
              r'Authorization':
                  'Bearer 4htbz9nLozJ_-Xw-13LpeVWrEIRWZt4IrgTOQXstx7M1DCVeUIoxIZkQ0XVLVEtD2Gy2Vp1FjA2WRz5DOpZMSxHfXVBLR3gi0DeMXIV3X1bCHYoMoJ-_TZLfBn0ZWnYx'
            },
            extra: _extra,
            contentType: 'application/json',
            baseUrl: baseUrl),
        data: _data);
    final value = _result.data;
    return value;
  }

  @override
  Future<String> business(locationName, locale) async {
    ArgumentError.checkNotNull(locationName, 'locationName');
    ArgumentError.checkNotNull(locale, 'locale');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = {'locale': locale};
    _data.removeWhere((k, v) => v == null);
    final _result = await _dio.request<String>('/v3/businesses/$locationName',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{
              r'Content-Type': 'application/json',
              r'Authorization':
                  'Bearer 4htbz9nLozJ_-Xw-13LpeVWrEIRWZt4IrgTOQXstx7M1DCVeUIoxIZkQ0XVLVEtD2Gy2Vp1FjA2WRz5DOpZMSxHfXVBLR3gi0DeMXIV3X1bCHYoMoJ-_TZLfBn0ZWnYx'
            },
            extra: _extra,
            contentType: 'application/json',
            baseUrl: baseUrl),
        data: _data);
    final value = _result.data;
    return value;
  }

  @override
  Future<String> review(id, locale) async {
    ArgumentError.checkNotNull(id, 'id');
    ArgumentError.checkNotNull(locale, 'locale');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = {'locale': locale};
    _data.removeWhere((k, v) => v == null);
    final _result = await _dio.request<String>('/v3/businesses/$id/reviews',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{
              r'Content-Type': 'application/json',
              r'Authorization':
                  'Bearer 4htbz9nLozJ_-Xw-13LpeVWrEIRWZt4IrgTOQXstx7M1DCVeUIoxIZkQ0XVLVEtD2Gy2Vp1FjA2WRz5DOpZMSxHfXVBLR3gi0DeMXIV3X1bCHYoMoJ-_TZLfBn0ZWnYx'
            },
            extra: _extra,
            contentType: 'application/json',
            baseUrl: baseUrl),
        data: _data);
    final value = _result.data;
    return value;
  }
}
