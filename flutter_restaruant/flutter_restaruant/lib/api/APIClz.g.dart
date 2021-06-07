// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'APIClz.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _APIClz implements APIClz {
  _APIClz(this._dio, {this.baseUrl = ""}) {
    ArgumentError.checkNotNull(_dio, '_dio');
    this.baseUrl ??= 'https://api.yelp.com';
  }

  final Dio _dio;

  String baseUrl;

  @override
  fetchToken(grantType, clientId, clientSecret) async {
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
    final Response<String> _result = await _dio.request('/oauth2/token',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'POST',
            headers: <String, dynamic>{},
            extra: _extra,
            contentType: 'application/x-www-form-urlencoded',
            baseUrl: baseUrl),
        data: _data);
    final value = _result.data;
    return Future.value(value);
  }

  @override
  businessesSearch(term, latitude, longitude, locale, limit,
      {openAt = "", sortBy = "", price = ""}) async {
    ArgumentError.checkNotNull(term, 'term');
    ArgumentError.checkNotNull(latitude, 'latitude');
    ArgumentError.checkNotNull(longitude, 'longitude');
    ArgumentError.checkNotNull(locale, 'locale');
    ArgumentError.checkNotNull(limit, 'limit');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
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
    final Response<String> _result = await _dio.request('/v3/businesses/search',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'POST',
            headers: <String, dynamic>{
              'Content-Type': 'application/json',
              'Authorization':
                  'Bearer 4htbz9nLozJ_-Xw-13LpeVWrEIRWZt4IrgTOQXstx7M1DCVeUIoxIZkQ0XVLVEtD2Gy2Vp1FjA2WRz5DOpZMSxHfXVBLR3gi0DeMXIV3X1bCHYoMoJ-_TZLfBn0ZWnYx'
            },
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = _result.data;
    return Future.value(value);
  }

  @override
  business(locationName, locale) async {
    ArgumentError.checkNotNull(locationName, 'locationName');
    ArgumentError.checkNotNull(locale, 'locale');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = {'locale': locale};
    final Response<String> _result =
        await _dio.request('/v3/businesses/$locationName',
            queryParameters: queryParameters,
            options: RequestOptions(
                method: 'GET',
                headers: <String, dynamic>{
                  'Content-Type': 'application/json',
                  'Authorization':
                      'Bearer 4htbz9nLozJ_-Xw-13LpeVWrEIRWZt4IrgTOQXstx7M1DCVeUIoxIZkQ0XVLVEtD2Gy2Vp1FjA2WRz5DOpZMSxHfXVBLR3gi0DeMXIV3X1bCHYoMoJ-_TZLfBn0ZWnYx'
                },
                extra: _extra,
                baseUrl: baseUrl),
            data: _data);
    final value = _result.data;
    return Future.value(value);
  }

  @override
  review(id, locale) async {
    ArgumentError.checkNotNull(id, 'id');
    ArgumentError.checkNotNull(locale, 'locale');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = {'locale': locale};
    final Response<String> _result =
        await _dio.request('/v3/businesses/$id/reviews',
            queryParameters: queryParameters,
            options: RequestOptions(
                method: 'GET',
                headers: <String, dynamic>{
                  'Content-Type': 'application/json',
                  'Authorization':
                      'Bearer 4htbz9nLozJ_-Xw-13LpeVWrEIRWZt4IrgTOQXstx7M1DCVeUIoxIZkQ0XVLVEtD2Gy2Vp1FjA2WRz5DOpZMSxHfXVBLR3gi0DeMXIV3X1bCHYoMoJ-_TZLfBn0ZWnYx'
                },
                extra: _extra,
                baseUrl: baseUrl),
            data: _data);
    final value = _result.data;
    return Future.value(value);
  }
}
