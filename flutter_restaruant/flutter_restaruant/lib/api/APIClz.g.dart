// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'APIClz.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _APIClz implements APIClz {
  _APIClz(this._dio, {this.baseUrl}) {
    ArgumentError.checkNotNull(_dio, '_dio');
    baseUrl ??= 'http://192.168.6.200:31199/';
  }

  final Dio _dio;

  String baseUrl;

  @override
  Future<ResultVo> login(account, password) async {
    ArgumentError.checkNotNull(account, 'account');
    ArgumentError.checkNotNull(password, 'password');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = {'account': account, 'password': password};
    _data.removeWhere((k, v) => v == null);
    final _result = await _dio.request<Map<String, dynamic>>('/v1/login',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'POST',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = ResultVo.fromJson(_result.data);
    return value;
  }
}
