import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../../api/api_clz.dart';
import '../dto/yelp_restaurant_detail_dto.dart';
import '../dto/yelp_restaurant_summary_dto.dart';
import '../dto/yelp_review_dto.dart';
import '../../domain/entities/restaurant_detail_entity.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/restaurant_detail_repository.dart';
import '../../manager/sign_in_manager.dart';
import '../../utils/constants.dart';

class RestaurantDetailRepo implements RestaurantDetailRepository {
  static const String favorCollectionName = 'favors';

  String _uid = '';

  RestaurantDetailRepo() {
    _uid = SignInManager().accountDto?.uid ?? '';
  }

  @override
  Future<RestaurantDetailEntity> fetchYelpRestaurantDetailInfo(
      String id) async {
    YelpRestaurantDetailDto detailDto =
        await GetIt.I<APIClz>().business(id, Constants.locale);
    return RestaurantDetailEntity.fromDto(detailDto);
  }

  @override
  Future<ReviewEntity> fetchYelpRestaurantReviewInfo(String id) async {
    YelpReviewDto reviewDto =
        await GetIt.I<APIClz>().review(id, Constants.locale);
    return ReviewEntity.fromDto(reviewDto);
  }

  @override
  Future<void> toggleFavor(RestaurantEntity summaryInfo) async {
    Map<String, dynamic> favorsMap = await _fetchFavorsMap();
    bool newFavor = !summaryInfo.favor;
    RestaurantEntity updatedEntity = summaryInfo.copyWith(favor: newFavor);

    if (newFavor) {
      // 若設定為最愛資料則新增
      YelpRestaurantSummaryDto dto = updatedEntity.toDto;
      String summaryInfoJsonStr = jsonEncode(dto.toJson());


      favorsMap[updatedEntity.id!] = summaryInfoJsonStr;
    } else {
      // 若設定為非最愛資料則刪除
      favorsMap.remove(updatedEntity.id!);
    }
    // 更新資料
    // ignore: unawaited_futures
    _updateFavorsMap(favorsMap);
  }

  Future<Map<String, dynamic>> _fetchFavorsMap() async {
    DocumentReference ref = FirebaseFirestore.instance
        .collection(favorCollectionName)
        .doc(_uid);
    DocumentSnapshot snapshots = await ref.get();
    Map<String, dynamic> favorsMap = (snapshots.data() != null)
        ? snapshots.data() as Map<String, dynamic>
        : <String, dynamic>{};

    return favorsMap;
  }

  Future<void> _updateFavorsMap(Map<String, dynamic> favorsMap) async {
    DocumentReference ref = FirebaseFirestore.instance
        .collection(favorCollectionName)
        .doc(_uid);

    // ignore: unawaited_futures
    ref.set(favorsMap, SetOptions(merge: false));
  }
}
