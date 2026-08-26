import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../dto/dto_barrel.dart';
import '../../api/api_barrel.dart';
import '../../domain/entities/entities_barrel.dart';
import '../../manager/manager_barrel.dart';

/// 最愛餐廳在 Firestore 的單一存取點。
///
/// 每一筆最愛存成 `favors/{uid}/items/{restaurantId}` 底下的一份 document，
/// 內容為 [YelpRestaurantSummaryDto] 的結構化欄位。三個 repository 先前各自
/// 複製了同一份讀寫邏輯，統一收斂在此。
///
/// 舊結構是單一 document `favors/{uid}`，key 為餐廳 id、value 為序列化後的
/// JSON 字串。那個結構有兩個無法迴避的缺陷——受 Firestore 單 document 1MiB
/// 上限約束，且「讀全量、改一筆、寫全量」在併發時會互相覆蓋（lost update）。
/// 改為 subcollection 後兩者都不是被緩解，而是根本不存在。舊資料由
/// [_migrateLegacyDocIfNeeded] 在首次讀取時搬移。
class FavorDataSource {
  static const String favorCollectionName = 'favors';
  static const String itemsSubcollectionName = 'items';

  /// 遷移完成標記，寫在舊 document 上。
  static const String migratedAtField = '_migratedAt';

  /// Firestore [WriteBatch] 的單批寫入上限。
  static const int _batchLimit = 500;

  final FirebaseFirestore? _firestoreOverride;

  FavorDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// uid would keep pointing at the previous user after a sign-out/sign-in.
  String get _uid => SignInManager().accountDto?.uid ?? '';

  /// 進行中的遷移，用來讓同一使用者的併發讀取共用同一次遷移。
  ///
  /// [fetchFavorIds]（主列表）與 [fetchFavorEntities]（最愛頁）是各自獨立的
  /// 進入點，兩個頁面同時載入時會各觸發一次遷移。重複遷移不會損毀資料
  /// （`set` 冪等），但會白白多付一輪讀寫配額。
  ///
  /// 連 uid 一起記：這是 lazy singleton，只記 Future 的話，A 帳號遷移完
  /// 換 B 帳號登入時會誤判為「已遷移」，B 的舊資料就永遠搬不過來。
  String? _migratingUid;
  Future<void>? _migration;

  DocumentReference get _doc =>
      _firestore.collection(favorCollectionName).doc(_uid);

  CollectionReference get _items => _doc.collection(itemsSubcollectionName);

  /// 讀出所有最愛餐廳的 id 集合。
  ///
  /// 只取 document id，不反序列化內容——主列表判斷「是否為最愛」只需要 id。
  ///
  /// 未登入時（訪客或尚未登入）沒有可查詢的 document，直接回傳空集合。
  /// 少了這道 guard，Firestore 會因空字串 doc id 拋出 [ArgumentError]——
  /// 它繼承 [Error] 而非 [Exception]，呼叫端的 `on Exception` 接不住，
  /// 會變成未捕捉錯誤並讓畫面卡在 loading。
  Future<Set<String>> fetchFavorIds() async {
    if (_uid.isEmpty) {
      return <String>{};
    }

    await _migrateLegacyDocIfNeeded();

    QuerySnapshot snapshot = await _items.get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  /// 讀出所有最愛餐廳，[RestaurantEntity.favor] 一律為 true。
  Future<List<RestaurantEntity>> fetchFavorEntities() async {
    if (_uid.isEmpty) {
      return <RestaurantEntity>[];
    }

    await _migrateLegacyDocIfNeeded();

    QuerySnapshot snapshot = await _items.get();

    return snapshot.docs.map((doc) {
      YelpRestaurantSummaryDto dto = YelpRestaurantSummaryDto.fromJson(
        doc.data() as Map<String, dynamic>,
      );
      dto.favor = true;

      return RestaurantEntity.fromDto(dto);
    }).toList();
  }

  /// 翻轉 [summaryInfo] 的最愛狀態並寫回 Firestore。
  ///
  /// 單筆 document 的寫入／刪除由 Firestore 保證原子性，不需要讀出全量再
  /// 覆寫——也就沒有多裝置併發互相覆蓋的問題。刻意不在此路徑做任何全量
  /// 讀取，這是本 method 正確性的前提。
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

    bool newFavor = !summaryInfo.favor;
    RestaurantEntity updatedEntity = summaryInfo.copyWith(favor: newFavor);
    DocumentReference itemDoc = _items.doc(updatedEntity.id!);

    // 必須等寫入完成，否則失敗時 UI 已顯示成功
    if (newFavor) {
      // toJson() 遞迴展開巢狀 DTO（見 YelpRestaurantSummaryDto 的
      // explicitToJson），產出的純量 map 才是 Firestore 收得下的形狀。
      await itemDoc.set(updatedEntity.toDto.toJson());
    } else {
      await itemDoc.delete();
    }

    return updatedEntity;
  }

  /// 解出舊 document 中單筆最愛的內容，格式不符時回傳 null。
  ///
  /// 舊 document 是 Firestore 上的既有資料，不由這版程式碼保證形狀——
  /// 可能被舊版本、其他客戶端或 Console 手動改過。[jsonDecode] 與型別轉換
  /// 失敗時拋的是 [FormatException] 與 [TypeError]，後者繼承 [Error]，
  /// 會穿透呼叫端的 `on Exception` 直達 UI，讓畫面卡在 loading——正是
  /// 外層那道 catch 想防止的情況。因此在這裡就地攔下。
  Map<String, dynamic>? _decodeLegacyEntry(MapEntry<String, dynamic> entry) {
    Object? value = entry.value;

    if (value is! String) {
      logger.e('最愛資料遷移：${entry.key} 的值不是字串，已跳過');
      return null;
    }

    try {
      Object? decoded = jsonDecode(value);

      if (decoded is! Map<String, dynamic>) {
        logger.e('最愛資料遷移：${entry.key} 解出的不是物件，已跳過');
        return null;
      }

      return decoded;
    } on FormatException catch (e, st) {
      logger.e('最愛資料遷移：${entry.key} 不是合法 JSON，已跳過', error: e, stackTrace: st);
      return null;
    }
  }

  /// 把舊的單一 document 結構搬到 subcollection，只在首次讀取時執行一次。
  ///
  /// 遷移全部成功才寫入 [migratedAtField] 標記；部分失敗時標記不會寫入，
  /// 下次讀取會重跑——重複 `set` 同一筆是冪等的，重跑無副作用。
  ///
  /// ponytail: 刻意不刪除舊 document。保留它才能在新版本出問題時退版回滾，
  /// 也是遷移失敗時的真相來源。確認使用者全數升級後再另案清理。
  Future<void> _migrateLegacyDocIfNeeded() {
    // 換帳號就重跑：快取只對同一個 uid 有效。
    final currentUid = _uid;
    if (_migratingUid != currentUid) {
      _migratingUid = currentUid;
      _migration = _runLegacyMigration(currentUid);
    }

    return _migration!;
  }

  Future<void> _runLegacyMigration(String uid) async {
    DocumentReference legacyDoc = _firestore
        .collection(favorCollectionName)
        .doc(uid);
    CollectionReference subCollection = legacyDoc.collection(
      itemsSubcollectionName,
    );

    try {
      DocumentSnapshot snapshot = await legacyDoc.get();
      Map<String, dynamic>? legacy = snapshot.data() as Map<String, dynamic>?;

      if (legacy == null || legacy.containsKey(migratedAtField)) {
        return;
      }

      List<MapEntry<String, dynamic>> entries = legacy.entries
          .where((entry) => entry.key != migratedAtField)
          .toList();

      for (int i = 0; i < entries.length; i += _batchLimit) {
        WriteBatch batch = _firestore.batch();
        for (MapEntry<String, dynamic> entry
            in entries.skip(i).take(_batchLimit)) {
          Map<String, dynamic>? decoded = _decodeLegacyEntry(entry);

          // 單筆壞資料不該擋住其餘幾百筆——跳過並記錄即可。
          if (decoded == null) {
            continue;
          }

          batch.set(subCollection.doc(entry.key), decoded);
        }
        await batch.commit();
      }

      // 全部成功才打標記。entries 為空（曾收藏後全部取消）時迴圈不執行，
      // 直接落到這裡打標記，否則每次讀取都會重跑一遍這個流程。
      await legacyDoc.set({
        migratedAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Exception catch (e, st) {
      // 遷移失敗不能讓最愛頁壞掉：舊資料仍完好，下次讀取會重試。
      // 清掉快取，否則這個已完成的 Future 會讓「下次重試」永遠不發生。
      _migratingUid = null;
      logger.e('最愛資料遷移失敗，將於下次讀取重試', error: e, stackTrace: st);
    }
  }
}
