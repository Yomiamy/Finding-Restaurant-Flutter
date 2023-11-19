import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_restaruant/api/APIClz.dart';
import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:flutter_restaruant/model/FilterConfigs.dart';
import 'package:flutter_restaruant/flow/favor/repository/FavorRepository.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';

class MainRepository {

  static const int _MAX_ITEMS_COUNT_IN_LIST = 50;
  static const String FAVOR_COLLECTION_NAME = "favors";

  Set<YelpRestaurantSummaryInfo> summaryInfoSet = Set();
  int _offset = 0;
  String _keyword = "";
  bool _isLoading = false;
  String _uid = "";

  MainRepository() {
    this._uid = SignInManager().accountInfo?.uid ?? "";

    this.reset();
  }

  void reset() {
    this._offset = 0;
    this._keyword = "";
    this._isLoading = false;

    this.summaryInfoSet.clear();
  }

  Future<List<YelpRestaurantSummaryInfo>> fetchYelpSearchInfo(double lat, double lng, int? price, int? openAt, String? sortByStr) async {
    if(this._isLoading) {
      // If new items is loading, then don't handle new fetching request until the old one completed.
      return await this.filterByKeyword(this._keyword, sortByStr);
    }

    this._isLoading = true;
    YelpSearchInfo searchInfo = await apiInstance.businessesSearch(
        term: "Restaurants",
        latitude: lat,
        longitude: lng,
        locale: Constants.LOCALE,
        price: price,
        openAt: openAt,
        sortBy: sortByStr,
        limit: MainRepository._MAX_ITEMS_COUNT_IN_LIST,
        offset: ++this._offset);
    this._isLoading = false;
    Map<String, dynamic> favorsMap = await this._fetchFavorsMap();

    // 檢查是否為最愛店家
    searchInfo.businesses?.forEach((summaryInfo) {
      summaryInfo.favor = (favorsMap.containsKey(summaryInfo.id));
    });
    this.summaryInfoSet.addAll(searchInfo.businesses ?? []);

    // Reference ref = FirebaseStorage.instance.ref("Gh3CuBx9LrhoTrBveY4B2OBLWvj2/test.png");
    return await this.filterByKeyword(this._keyword, sortByStr);
  }

  Future<List<YelpRestaurantSummaryInfo>> filterByKeyword(String keyword, String? sortByStr) async {
    this._keyword = keyword;

    if(keyword.isNotEmpty) {
      List<YelpRestaurantSummaryInfo> filteredList = this.summaryInfoSet.where((element) {
        return (element.name?.contains(keyword) ?? false)
            || (element.categoriesStr.contains(keyword))
            || (element.location?.displayAddressStr.contains(keyword) ?? false);
      }).toList();

      return this._getSortedInfoList(sortByStr, filteredList);
    } else {
      return this._getSortedInfoList(sortByStr, this.summaryInfoSet.toList());
    }
  }

  List<YelpRestaurantSummaryInfo> _getSortedInfoList(String? sortByStr, List<YelpRestaurantSummaryInfo> summaryInfos) {
    sortByStr = sortByStr ?? SortBy.best_match.toShortString();
    SortBy sortBy = SortBy.values.firstWhere((element) => element.toShortString() == sortByStr);

    summaryInfos.sort((info1, info2) {
      switch(sortBy) {
        case SortBy.distance:
          double dist1 = info1.distance ?? 0;
          double dist2 = info2.distance ?? 0;

          return dist1.compareTo(dist2);
        case SortBy.review_count:
          int reviewCount1 = info1.review_count ?? 0;
          int reviewCount2 = info2.review_count ?? 0;

          return reviewCount2.compareTo(reviewCount1);
        case SortBy.rating:
          double rating1 = info1.rating ?? 0;
          double rating2 = info2.rating ?? 0;

          return rating2.compareTo(rating1);
        default:
          return 0;
      }
    });

    return summaryInfos;
  }

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
