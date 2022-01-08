import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';

class FavorRepository {
  Future<List<YelpRestaurantSummaryInfo>> fetchFavorInfos(String uid) async {
    DocumentSnapshot snapshots = await FirebaseFirestore.instance
                                              .collection("favors")
                                              .doc(uid)
                                              .get();
    Map<String, dynamic> favorMap = snapshots.data() as Map<String, dynamic>;
    return favorMap.values.map((value) => YelpRestaurantSummaryInfo.fromJson(value)).toList();
  }
}