import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';

class FavorRepository {
  
  static const String FAVOR_COLLECTION_NAME = "favors";

  String _uid = "";

  FavorRepository() {
    this._uid = SignInManager().accountInfo?.uid ?? "";
  }
  
  Future<List<YelpRestaurantSummaryInfo>> fetchFavorInfos() async {
    DocumentSnapshot snapshots = await FirebaseFirestore.instance
                                              .collection(FAVOR_COLLECTION_NAME)
                                              .doc(this._uid)
                                              .get();
    Map<String, dynamic> favorMap = (snapshots.data() != null) ? snapshots.data() as Map<String, dynamic> : Map<String, dynamic>();
    return favorMap.values.map((value) => YelpRestaurantSummaryInfo.fromJson(jsonDecode(value))).toList();
  }

  Future<void> toggleFavor(YelpRestaurantSummaryInfo summaryInfo) async {
    DocumentReference ref = FirebaseFirestore.instance.collection(FAVOR_COLLECTION_NAME).doc(this._uid);
    DocumentSnapshot snapshots = await ref.get();
    Map<String, dynamic> favorsMap = (snapshots.data() != null) ? snapshots.data() as Map<String, dynamic> : Map<String, dynamic>();
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
    ref.set(favorsMap, SetOptions(merge: false));
  }
}