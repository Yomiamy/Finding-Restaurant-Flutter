import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';

class FavorRepository {
  
  static String _sFavorCollectionName = "favors";
  
  Future<List<YelpRestaurantSummaryInfo>> fetchFavorInfos(String uid) async {
    DocumentSnapshot snapshots = await FirebaseFirestore.instance
                                              .collection(_sFavorCollectionName)
                                              .doc(uid)
                                              .get();
    Map<String, dynamic> favorMap = (snapshots.data() != null) ? snapshots.data() as Map<String, dynamic> : Map<String, dynamic>();
    return favorMap.values.map((value) => YelpRestaurantSummaryInfo.fromJson(value)).toList();
  }

  Future<void> updateFavorInfo(String uid, YelpRestaurantSummaryInfo summaryInfo) async {
    DocumentReference ref = FirebaseFirestore.instance.collection(_sFavorCollectionName).doc(uid);
    DocumentSnapshot snapshots = await ref.get();
    Map<String, dynamic> favorsMap = snapshots.data() as Map<String, dynamic>;
    bool isFavor = summaryInfo.favor ?? false;

    if (isFavor) {
      // 若設定為最愛資料則新增
      favorsMap[summaryInfo.id!] = summaryInfo.toJson();
    } else {
      // 若設定為非最愛資料則刪除
      favorsMap.remove(summaryInfo.id!);
    }
    // 更新資料
    ref.set(favorsMap);
  }
}