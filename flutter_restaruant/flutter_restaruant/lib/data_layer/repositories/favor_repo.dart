import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../dto/yelp_restaurant_summary_dto.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../domain/repositories/favor_repository.dart';
import '../../manager/sign_in_manager.dart';

class FavorRepo implements FavorRepository {
  static const String favorCollectionName = 'favors';

  String _uid = '';
  List<RestaurantEntity> _favorInfos = [];

  FavorRepo() {
    _uid = SignInManager().accountDto?.uid ?? '';
  }

  @override
  Future<List<RestaurantEntity>> fetchFavorInfos(
      bool isRefreshLocalOnly) async {
    if (isRefreshLocalOnly) {
      _favorInfos =
          _favorInfos.where((element) => element.favor).toList();
    } else {
      DocumentSnapshot snapshots = await FirebaseFirestore.instance
          .collection(favorCollectionName)
          .doc(_uid)
          .get();
      Map<String, dynamic> favorMap = (snapshots.data() != null)
          ? snapshots.data() as Map<String, dynamic>
          : <String, dynamic>{};
      _favorInfos = favorMap.values.map((value) {
        YelpRestaurantSummaryDto dto =
            YelpRestaurantSummaryDto.fromJson(jsonDecode(value));
        dto.favor = true;

        return RestaurantEntity.fromDto(dto);
      }).toList();
    }

    return _favorInfos;
  }

  @override
  Future<void> toggleFavor(RestaurantEntity summaryInfo) async {
    DocumentReference ref = FirebaseFirestore.instance
        .collection(favorCollectionName)
        .doc(_uid);
    DocumentSnapshot snapshots = await ref.get();
    Map<String, dynamic> favorsMap = (snapshots.data() != null)
        ? snapshots.data() as Map<String, dynamic>
        : <String, dynamic>{};
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
    ref.set(favorsMap, SetOptions(merge: false));
  }
}
