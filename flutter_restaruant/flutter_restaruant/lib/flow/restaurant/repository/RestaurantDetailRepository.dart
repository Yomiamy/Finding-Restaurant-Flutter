import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpReviewInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class RestaurantDetailRepository {

  static const String FAVOR_COLLECTION_NAME = "favors";

  String _uid = "";

  RestaurantDetailRepository() {
    this._uid = SignInManager().accountInfo?.uid ?? "";
  }

  Future<YelpRestaurantDetailInfo> fetchYelpRestaurantDetailInfo(String id) async => apiInstance.business(
      id,
      Constants.LOCALE
  );

  Future<YelpReviewInfo> fetchYelpRestaurantReviewInfo(String id) async => apiInstance.review(
      id,
      Constants.LOCALE
  );

  Future<void> toggleFavor(YelpRestaurantSummaryInfo summaryInfo) async {
    Map<String, dynamic> favorsMap = await this._fetchFavorsMap();
    summaryInfo.favor = !summaryInfo.favor;

    if (summaryInfo.favor) {
      // 若設定為最愛資料則新增
      String summaryInfoJsonStr = jsonEncode(summaryInfo);

      favorsMap[summaryInfo.id!] = summaryInfoJsonStr;
    } else {
      // 若設定為非最愛資料則刪除
      favorsMap.remove(summaryInfo.id!);
    }
    // 更新資料
    this._updateFavorsMap(favorsMap);
  }

  Future<Map<String, dynamic>> _fetchFavorsMap() async {
    DocumentReference ref = FirebaseFirestore.instance.collection(FAVOR_COLLECTION_NAME).doc(this._uid);
    DocumentSnapshot snapshots = await ref.get();
    Map<String, dynamic> favorsMap = (snapshots.data() != null) ? snapshots.data() as Map<String, dynamic> : Map<String, dynamic>();

    return favorsMap;
  }

  Future<void> _updateFavorsMap(Map<String, dynamic> favorsMap) async {
    DocumentReference ref = FirebaseFirestore.instance.collection(FAVOR_COLLECTION_NAME).doc(this._uid);

    ref.set(favorsMap, SetOptions(merge: false));
  }
}