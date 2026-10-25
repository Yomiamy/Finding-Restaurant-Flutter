import 'package:flutter_restaruant/api/dto/yelp_engagement_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

class _Data {
  static const Map<String, dynamic> full = {
    'data': [
      {
        'business_id': 'WavvLdfdP6g8aZTtbBQHTw',
        'metrics': [
          {
            'start_of_week_date': '2026-10-19',
            'engagement_metric': 12,
            'intent_metric': 5,
            'transaction_metric': 2,
          },
        ],
      },
    ],
  };

  // start_of_week_date 是 metric 唯一必有的欄位。
  static const Map<String, dynamic> dateOnly = {
    'data': [
      {
        'business_id': 'WavvLdfdP6g8aZTtbBQHTw',
        'metrics': [
          {'start_of_week_date': '2026-10-19'},
        ],
      },
    ],
  };
}

void main() {
  group('YelpEngagementDto', () {
    test('完整欄位逐欄解析', () {
      final dto = YelpEngagementDto.fromJson(_Data.full);
      expect(dto.data, hasLength(1));
      final b = dto.data?.first;
      expect(b?.businessId, 'WavvLdfdP6g8aZTtbBQHTw');
      expect(b?.metrics, hasLength(1));
      final m = b?.metrics?.first;
      expect(m?.startOfWeekDate, '2026-10-19');
      expect(m?.engagementMetric, 12);
      expect(m?.intentMetric, 5);
      expect(m?.transactionMetric, 2);
    });

    test('metric 只有 start_of_week_date 時，其餘三欄為 null', () {
      final dto = YelpEngagementDto.fromJson(_Data.dateOnly);
      final m = dto.data?.first.metrics?.first;
      expect(m?.startOfWeekDate, '2026-10-19');
      expect(m?.engagementMetric, isNull);
      expect(m?.intentMetric, isNull);
      expect(m?.transactionMetric, isNull);
    });

    // 直接傳 toJson() 的 map，不經 jsonEncode：沒有 explicitToJson 的話，
    // data 與 metrics 兩層的 List 元素仍是 DTO 物件，fromJson 會因元素不是 Map 而拋錯。
    test('值相等與 round-trip', () {
      final dto = YelpEngagementDto.fromJson(_Data.full);
      expect(YelpEngagementDto.fromJson(dto.toJson()), dto);
    });

    test('型別不符時拋出 CheckedFromJsonException', () {
      expect(
        () => YelpEngagementDto.fromJson(const {'data': 'x'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
