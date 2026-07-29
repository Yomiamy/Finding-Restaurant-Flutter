import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaruant/data_layer/dto/account_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_restaurant_business_time_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_restaurant_category_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_restaurant_coordinates_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_restaurant_detail_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_restaurant_hours_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_restaurant_location_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_restaurant_summary_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_review_detail_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_review_dto.dart';
import 'package:flutter_restaruant/data_layer/dto/yelp_reviewer_dto.dart';

import 'package:flutter_restaruant/domain/entities/user_entity.dart';
import 'package:flutter_restaruant/domain/entities/restaurant_business_time_entity.dart';
import 'package:flutter_restaruant/domain/entities/restaurant_category_entity.dart';
import 'package:flutter_restaruant/domain/entities/restaurant_coordinates_entity.dart';
import 'package:flutter_restaruant/domain/entities/restaurant_detail_entity.dart';
import 'package:flutter_restaruant/domain/entities/restaurant_hours_entity.dart';
import 'package:flutter_restaruant/domain/entities/restaurant_location_entity.dart';
import 'package:flutter_restaruant/domain/entities/restaurant_entity.dart';
import 'package:flutter_restaruant/domain/entities/review_detail_entity.dart';
import 'package:flutter_restaruant/domain/entities/review_entity.dart';
import 'package:flutter_restaruant/domain/entities/reviewer_entity.dart';


void main() {
  group('Empirical Stress Tests - Milestone 3 DTO & Domain Entity Separation', () {
    test('1. Null field handling in all DTO toEntity() mappings', () {
      final accountDto = AccountDto(type: AccountType.google);
      final userEntity = UserEntity.fromDto(accountDto);
      expect(userEntity.uid, isNull);
      expect(userEntity.account, isNull);
      expect(userEntity.type, AccountType.google);

      final bizTimeDto = YelpRestaurantBusinessTimeDto();
      final bizTimeEntity = RestaurantBusinessTimeEntity.fromDto(bizTimeDto);
      expect(bizTimeEntity.isOvernight, isNull);
      expect(bizTimeEntity.start, isNull);
      expect(bizTimeEntity.end, isNull);
      expect(bizTimeEntity.day, isNull);

      final catDto = YelpRestaurantCategoryDto();
      final catEntity = RestaurantCategoryEntity.fromDto(catDto);
      expect(catEntity.alias, isNull);
      expect(catEntity.title, isNull);

      final coordDto = YelpRestaurantCoordinatesDto();
      final coordEntity = RestaurantCoordinatesEntity.fromDto(coordDto);
      expect(coordEntity.latitude, isNull);
      expect(coordEntity.longitude, isNull);

      final locDto = YelpRestaurantLocationDto();
      final locEntity = RestaurantLocationEntity.fromDto(locDto);
      expect(locEntity.address1, isNull);
      expect(locEntity.displayAddress, isNull);
      expect(locEntity.displayAddressStr, '');

      final hoursDto = YelpRestaurantHoursDto();
      final hoursEntity = RestaurantHoursEntity.fromDto(hoursDto);
      expect(hoursEntity.isOpenNow, isNull);
      expect(hoursEntity.open, isNull);

      final detailDto = YelpRestaurantDetailDto();
      final detailEntity = RestaurantDetailEntity.fromDto(detailDto);
      expect(detailEntity.name, isNull);
      expect(detailEntity.categories, isNull);
      expect(detailEntity.location, isNull);

      final summaryDto = YelpRestaurantSummaryDto();
      final summaryEntity = RestaurantEntity.fromDto(summaryDto);
      expect(summaryEntity.id, isNull);
      expect(summaryEntity.categories, isNull);
      expect(summaryEntity.categoriesStr, '');

      final reviewerDto = YelpReviewerDto();
      final reviewerEntity = ReviewerEntity.fromDto(reviewerDto);
      expect(reviewerEntity.name, isNull);

      final reviewDetailDto = YelpReviewDetailDto();
      final reviewDetailEntity = ReviewDetailEntity.fromDto(reviewDetailDto);
      expect(reviewDetailEntity.id, isNull);
      expect(reviewDetailEntity.user, isNull);

      final reviewDto = YelpReviewDto();
      final reviewEntity = ReviewEntity.fromDto(reviewDto);
      expect(reviewEntity.total, isNull);
      expect(reviewEntity.reviews, isNull);
    });

    test('2. Round-trip mapping: DTO -> Entity -> DTO with full data', () {
      final catDto = YelpRestaurantCategoryDto(alias: 'italian', title: 'Italian');
      final locDto = YelpRestaurantLocationDto(
        address1: 'Sec 1',
        city: 'Taipei',
        displayAddress: ['Sec 1, ', 'Taipei'],
      );
      final coordDto = YelpRestaurantCoordinatesDto(latitude: 25.03, longitude: 121.56);

      final summaryDto = YelpRestaurantSummaryDto(
        id: 'r_100',
        name: 'Pasta House',
        imageUrl: 'http://img.com/pasta.jpg',
        reviewCount: 50,
        rating: 4.7,
        price: '\$\$\$',
        phone: '+88612345678',
        distance: 350.2,
        categories: [catDto],
        location: locDto,
        coordinates: coordDto,
        favor: true,
      );

      final entity = RestaurantEntity.fromDto(summaryDto);
      expect(entity.id, 'r_100');
      expect(entity.categoriesStr, 'Italian');
      expect(entity.location?.displayAddressStr, 'Sec 1, Taipei');

      final backDto = entity.toDto;
      expect(backDto.id, 'r_100');
      expect(backDto.name, 'Pasta House');
      expect(backDto.categories?.first.title, 'Italian');
      expect(backDto.location?.displayAddress, ['Sec 1, ', 'Taipei']);
      expect(backDto.favor, true);
    });

    test('3. Edge cases in Category and Location formatting', () {
      // Category title is null
      const catNullTitle = RestaurantCategoryEntity(alias: 'cat1', title: null);
      const catValidTitle = RestaurantCategoryEntity(alias: 'cat2', title: 'Bistro');
      const restEntity1 = RestaurantEntity(categories: [catNullTitle, catValidTitle]);
      expect(restEntity1.categoriesStr, ' Bistro');

      // Empty categories
      const restEntity2 = RestaurantEntity(categories: []);
      expect(restEntity2.categoriesStr, '');

      // Null categories
      const restEntity3 = RestaurantEntity(categories: null);
      expect(restEntity3.categoriesStr, '');

      // Location displayAddress empty
      const locEmpty = RestaurantLocationEntity(displayAddress: []);
      expect(locEmpty.displayAddressStr, '');

      // Location displayAddress null
      const locNull = RestaurantLocationEntity(displayAddress: null);
      expect(locNull.displayAddressStr, '');
    });

    test('4. Equality checks for RestaurantEntity & DTOs with null vs non-null IDs', () {
      const eNull1 = RestaurantEntity(id: null, name: 'A');
      const eNull2 = RestaurantEntity(id: null, name: 'B');
      const eVal1 = RestaurantEntity(id: 'id_1', name: 'A');
      const eVal2 = RestaurantEntity(id: 'id_1', name: 'B');
      const eVal3 = RestaurantEntity(id: 'id_2', name: 'A');

      // Different instances with null ID must NOT be equal
      expect(eNull1 == eNull2, false);
      expect(eNull1.hashCode, 0);

      // Same instance with null ID IS equal (identical check)
      expect(eNull1 == eNull1, true);

      // Same ID -> equal
      expect(eVal1 == eVal2, true);
      expect(eVal1.hashCode, eVal2.hashCode);

      // Different ID -> not equal
      expect(eVal1 == eVal3, false);

      // Null ID vs non-null ID -> not equal
      expect(eNull1 == eVal1, false);
      expect(eVal1 == eNull1, false);

      // DTO equality check
      final dtoNull1 = YelpRestaurantSummaryDto(id: null);
      final dtoNull2 = YelpRestaurantSummaryDto(id: null);
      final dtoVal1 = YelpRestaurantSummaryDto(id: 'id_1');
      final dtoVal2 = YelpRestaurantSummaryDto(id: 'id_1');

      expect(dtoNull1 == dtoNull2, false);
      expect(dtoNull1 == dtoNull1, true);
      expect(dtoVal1 == dtoVal2, true);


    });
  });
}
