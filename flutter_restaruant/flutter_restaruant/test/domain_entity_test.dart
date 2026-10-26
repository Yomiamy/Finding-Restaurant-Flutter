import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/data_layer/models/model_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';

class _Data {
  static const String id = 'bistro-101-id';
  static const String alias = 'bistro-101';
  static const String price = '\$\$';
  static const String url = 'https://www.yelp.com/biz/bistro-101';
  static const String displayPhone = '(02) 2345-6789';
  static const List<String> transactions = ['delivery'];
}

void main() {
  group('Domain Entities & DTO Separation Tests', () {
    test('RestaurantEntity equality check is null-safe', () {
      const entity1 = RestaurantEntity(id: null, name: 'RestA');
      const entity2 = RestaurantEntity(id: null, name: 'RestB');
      const entity3 = RestaurantEntity(id: '123', name: 'RestC');
      const entity4 = RestaurantEntity(id: '123', name: 'RestD');

      expect(entity1 == entity2, false);
      expect(entity1 == entity3, false);
      expect(entity3 == entity4, true);
    });

    test(
      'YelpRestaurantSummaryDto converts to/from RestaurantEntity correctly',
      () {
        final dto = YelpRestaurantSummaryDto(
          id: 'rest_01',
          name: 'Gourmet Place',
          imageUrl: 'http://img.com/a.jpg',
          reviewCount: 42,
          rating: 4.5,
          price: '\$\$',
          phone: '123456',
          distance: 120.5,
          favor: true,
        );

        final entity = RestaurantEntity.fromDto(dto);
        expect(entity.id, 'rest_01');
        expect(entity.name, 'Gourmet Place');
        expect(entity.reviewCount, 42);
        expect(entity.rating, 4.5);
        expect(entity.favor, true);

        final backDto = entity.toDto;
        expect(backDto.id, 'rest_01');
        expect(backDto.name, 'Gourmet Place');
        expect(backDto.reviewCount, 42);
        expect(backDto.rating, 4.5);
        expect(backDto.favor, true);
      },
    );

    test('YelpRestaurantDetailDto to RestaurantDetailEntity mapping', () {
      final detailDto = YelpRestaurantDetailDto(
        name: 'Bistro 101',
        imageUrl: 'http://img.com/bistro.jpg',
        isClosed: false,
        reviewCount: 100,
        rating: 4.8,
        phone: '987654321',
      );

      final RestaurantDetailEntity detailEntity =
          RestaurantDetailEntity.fromDto(detailDto);
      expect(detailEntity.name, 'Bistro 101');
      expect(detailEntity.isClosed, false);
      expect(detailEntity.rating, 4.8);
    });

    test('RestaurantDetailEntity.fromDto maps id/price/url/displayPhone', () {
      final entity = RestaurantDetailEntity.fromDto(
        YelpRestaurantDetailDto(
          id: _Data.id,
          price: _Data.price,
          url: _Data.url,
          displayPhone: _Data.displayPhone,
        ),
      );

      expect(entity.id, _Data.id);
      expect(entity.price, _Data.price);
      expect(entity.url, _Data.url);
      expect(entity.displayPhone, _Data.displayPhone);
    });

    test('RestaurantDetailEntity.toDto writes back the 4 fields only', () {
      final dto = RestaurantDetailEntity.fromDto(
        YelpRestaurantDetailDto(
          id: _Data.id,
          alias: _Data.alias,
          price: _Data.price,
          url: _Data.url,
          displayPhone: _Data.displayPhone,
          isClaimed: true,
          transactions: _Data.transactions,
        ),
      ).toDto;

      expect(dto.id, _Data.id);
      expect(dto.price, _Data.price);
      expect(dto.url, _Data.url);
      expect(dto.displayPhone, _Data.displayPhone);
      // 刻意有損（規格 §3.1）：Entity 不攜帶這 3 欄。
      expect(dto.alias, isNull);
      expect(dto.isClaimed, isNull);
      expect(dto.transactions, isNull);
    });

    test('Empty DTO leaves the 4 new entity fields null', () {
      final entity = RestaurantDetailEntity.fromDto(YelpRestaurantDetailDto());

      expect(entity.id, isNull);
      expect(entity.price, isNull);
      expect(entity.url, isNull);
      expect(entity.displayPhone, isNull);
    });

    test('YelpReviewDto to ReviewEntity mapping', () {
      final reviewDto = YelpReviewDto(
        total: 5,
        possibleLanguages: ['en', 'zh'],
      );

      final ReviewEntity reviewEntity = ReviewEntity.fromDto(reviewDto);
      expect(reviewEntity.total, 5);
      expect(reviewEntity.possibleLanguages, contains('zh'));
    });

    test(
      'Category and Location getters function cleanly in domain entities',
      () {
        const category = RestaurantCategoryEntity(
          alias: 'sushi',
          title: 'Japanese Sushi',
        );
        const location = RestaurantLocationEntity(
          address1: '123 Main St',
          city: 'Taipei',
          displayAddress: ['123 Main St, ', 'Taipei City'],
        );

        const restaurant = RestaurantEntity(
          id: '1',
          categories: [category],
          location: location,
        );

        expect(restaurant.categoriesStr, 'Japanese Sushi');
        expect(
          restaurant.location?.displayAddressStr,
          '123 Main St, Taipei City',
        );
      },
    );

    test('AccountModel to UserEntity mapping and round-trip', () {
      final accountDto = AccountModel(
        type: AccountType.google,
        uid: 'user_123',
        account: 'test@example.com',
      );

      final userEntity = UserEntity.fromDto(accountDto);
      expect(userEntity.type, AccountTypeModel.google);
      expect(userEntity.uid, 'user_123');
      expect(userEntity.account, 'test@example.com');

      final backToDto = userEntity.toDto;
      expect(backToDto.type, AccountType.google);
      expect(backToDto.uid, 'user_123');
      expect(backToDto.account, 'test@example.com');
    });
  });
}
