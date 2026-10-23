import 'package:dio/dio.dart';
import 'package:flutter_restaruant/api/dio/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // release build 以 isLogEnabled: kDebugMode 關閉 log；測試環境 kDebugMode 恆為 true，故直接鎖開關本身。
  group('DioClient LogInterceptor', () {
    test('isLogEnabled 為 false 時不掛 LogInterceptor', () {
      final client = DioClient(isLogEnabled: false);
      expect(client.dio.interceptors.whereType<LogInterceptor>(), isEmpty);
    });

    test('isLogEnabled 為 true 時掛上 LogInterceptor', () {
      final client = DioClient(isLogEnabled: true);
      expect(client.dio.interceptors.whereType<LogInterceptor>(), hasLength(1));
    });
  });
}
