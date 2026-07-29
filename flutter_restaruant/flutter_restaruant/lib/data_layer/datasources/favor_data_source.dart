import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../dto/yelp_restaurant_summary_dto.dart';
import '../../domain/entities/restaurant_entity.dart';
import '../../manager/sign_in_manager.dart';

/// 最愛餐廳在 Firestore 的單一存取點。
///
/// 每位使用者的最愛存成一份 document，key 為餐廳 id、value 為序列化後的
/// [YelpRestaurantSummaryDto] JSON 字串。三個 repository 先前各自複製了同一份
/// 讀寫邏輯，統一收斂在此。
class FavorDataSource {
  static const String favorCollectionName = 'favors';

  /// Resolved per call: this data source is a lazy singleton, so caching the
  /// uid would keep pointing at the previous user after a sign-out/sign-in.
  String get _uid => SignInManager().accountDto?.uid ?? '';

  DocumentReference get _doc =>
      FirebaseFirestore.instance.collection(favorCollectionName).doc(_uid);

  /// 讀出原始的最愛 map，key 為餐廳 id。
  ///
  /// 未登入時（訪客或尚未登入）沒有可查詢的 document，直接回傳空 map。
  /// 少了這道 guard，Firestore 會因空字串 doc id 拋出 [ArgumentError]——
  /// 它繼承 [Error] 而非 [Exception]，呼叫端的 `on Exception` 接不住，
  /// 會變成未捕捉錯誤並讓畫面卡在 loading。
  Future<Map<String, dynamic>> fetchFavorsMap() async {
    if (_uid.isEmpty) {
      return <String, dynamic>{};
    }

    DocumentSnapshot snapshot = await _doc.get();

    return (snapshot.data() != null)
        ? snapshot.data() as Map<String, dynamic>
        : <String, dynamic>{};
  }

  /// 讀出所有最愛餐廳，[RestaurantEntity.favor] 一律為 true。
  Future<List<RestaurantEntity>> fetchFavorEntities() async {
    Map<String, dynamic> favorsMap = await fetchFavorsMap();

    return favorsMap.values.map((value) {
      YelpRestaurantSummaryDto dto =
          YelpRestaurantSummaryDto.fromJson(jsonDecode(value));
      dto.favor = true;

      return RestaurantEntity.fromDto(dto);
    }).toList();
  }

  /// 翻轉 [summaryInfo] 的最愛狀態並寫回 Firestore。
  ///
  /// 回傳實際被持久化的 entity，呼叫端直接採用即可，不需自行再推導一次。
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo) async {
    // 寫入需要真實的使用者。UI 層已在唯一入口（RestaurantHeadCell）攔下訪客，
    // 走到這裡代表攔截失效——直接失敗，不要無聲寫進空 doc id。
    // 用 throw 而非 assert：assert 在 release build 會被移除，正是最需要
    // 這道防護的環境。
    if (_uid.isEmpty) {
      throw StateError('toggleFavor requires a signed-in user');
    }

    Map<String, dynamic> favorsMap = await fetchFavorsMap();
    bool newFavor = !summaryInfo.favor;
    RestaurantEntity updatedEntity = summaryInfo.copyWith(favor: newFavor);

    if (newFavor) {
      // 若設定為最愛資料則新增
      favorsMap[updatedEntity.id!] = jsonEncode(updatedEntity.toDto.toJson());
    } else {
      // 若設定為非最愛資料則刪除
      favorsMap.remove(updatedEntity.id!);
    }

    // 必須等寫入完成，否則失敗時 UI 已顯示成功
    await _doc.set(favorsMap, SetOptions(merge: false));

    return updatedEntity;
  }
}
