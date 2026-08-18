# 實作計畫：Firestore 最愛改用 Subcollection

- **對應規格**：`docs/features/2026-08-18-favor-subcollection.md`
- **產出日期**：2026-08-18
- **異動集中度**：核心變更集中在**單一檔案** `lib/data_layer/datasources/favor_data_source.dart`，
  外加一處呼叫端調整與測試。

---

## 核心判斷（Linus 式）

**✅ 值得做。** 這不是臆想威脅：

- 1 MiB 上限是 Firestore 的**硬性限制**，撞牆後連刪除都做不到，使用者無法自救。
- read-modify-write 的 lost update 是**教科書等級的併發缺陷**，快速連點就能重現，且**靜默無錯誤**。

**關鍵洞察 — 資料結構錯了，不是程式碼錯了。**

現在的 `toggleFavor` 做了三件事：讀全量、改一筆、寫全量。三件事裡有兩件是多餘的。
正確的資料結構下，「翻轉一筆最愛」應該就是**一次針對該筆的寫入**：

```dart
newFavor ? await _items.doc(id).set(json) : await _items.doc(id).delete();
```

沒有讀取、沒有 merge 策略、沒有競態、沒有大小上限。**特殊情況全部消失**——
這是換角度重寫問題，而不是在舊結構上加 transaction 或重試補丁。

**最大破壞風險：安全規則沒同步改 → 全面 permission-denied。** 這在規格中已列為使用者行動項。
次高風險是既有使用者的最愛資料遺失，由下方的遷移決策處理。

---

## 關鍵設計決策

### 決策 1：路徑設計 — `favors/{uid}/items/{restaurantId}`

**採用 `favors/{uid}/items/{restaurantId}`（單層 subcollection），不採 `users/{uid}/saved_lists/{listId}/items/{...}`。**

理由：

1. **保留既有 root collection 名稱 `favors`**。`FavorDataSource.favorCollectionName = 'favors'` 不變，
   uid document 的位置不變。這讓遷移程式碼能在**同一棵樹**下操作，也讓安全規則的改動範圍最小
   （只需把既有 `match /favors/{uid}` 區塊擴充到子層，而非新增一整組 `users/**` 規則）。
2. **不引入 `listId`**。本次沒有多套名單 UI，硬塞一個永遠等於 `'default'` 的 `listId`
   就是「留給未來的 scaffolding」，Ponytail 規則明文禁止。
3. **未來可平滑升級**。要升級到 F-2.1 完整結構時，
   `favors/{uid}/items/*` → `users/{uid}/saved_lists/{listId}/items/*` 是一次一對一的
   document 搬移（每筆 item 的 schema 完全相同，只是換掛載點），寫一支遷移腳本即可，
   **不會因為現在少了一層而變得更難**。反過來說，現在就多做一層 `listId`，
   到時如果名單模型改成別的樣子（例如 tag-based 而非 list-based），那層反而是負債。

> **結論**：現在少做一層，未來的遷移成本不變；現在多做一層，現在就要付成本且未來未必用得上。

### 決策 2：既有資料遷移 — **採用「讀取時合併 + 一次性 lazy migration，且不刪除舊 document」**

這是本計畫**最重要**的決策。明確建議如下（非選項列表）：

**採用：lazy migration on first read，寫入 subcollection 後保留舊 document 不刪。**

具體行為：

1. `fetchFavorIds()` / `fetchFavorEntities()` 讀取時，**先讀 subcollection**。
2. 若 subcollection 為空 **且** 舊 `favors/{uid}` document 存在且非空
   → 判定為「尚未遷移的既有使用者」，執行一次遷移：用 `WriteBatch` 把舊 map 的每筆
   寫入 `favors/{uid}/items/{restaurantId}`，然後**直接使用剛遷移的資料**回傳給呼叫端。
3. 遷移成功後**不刪除**舊 document。

**為什麼要遷移（而非放棄舊資料）？**
最愛是使用者主動累積的個人資料，帶有情感價值。不遷移＝所有既有使用者升級後最愛全空，
這是 Never break userspace 的直接違反，也是最容易招致負評與流失的那種 bug。成本只有數十行程式碼，
沒有理由不做。

**為什麼是 lazy（首次讀取時）而非啟動時或後端腳本？**

- 本 repo 是純 client App，**沒有 Cloud Functions、沒有後端遷移腳本的執行環境**。
  唯一能碰到使用者資料的地方就是 client。
- 放在 App 啟動時做，會讓所有使用者（包括訪客、包括沒有最愛的人）都多付一次讀取與啟動延遲。
  放在「真的要用到最愛」的那一刻做，成本只落在需要的人身上，且**遷移與讀取共用同一次查詢**——
  不多花任何一次 round trip 來判斷「要不要遷移」。
- 只在 subcollection 為空時觸發，遷移完成後的每次讀取都只是一次 collection query，**零額外開銷**。

**為什麼不刪除舊 document？**

- **可回滾**。若新版本上線後發現問題需要退版，舊版 App 讀舊 document 仍然完整可用。
  刪掉就是單向門，出事只能靠使用者重新收藏。
- **遷移失敗的天然保護**。批次寫入若部分失敗，舊資料仍是完好的真相來源，下次啟動可重試。
- 成本只是每位使用者一份 ≤1 MiB 的殘留 document。相較於資料遺失的風險，這個儲存成本可以忽略。
- 清理留到「確認全部使用者已升級」之後另案處理，並在程式碼中以 `ponytail:` 註解標明。

**遷移失敗如何處理？**

- 遷移是 `WriteBatch`（Firestore 保證 batch 為原子操作，最多 500 筆）。
  一般使用者的最愛量遠低於 500；**超過 500 筆時分批寫入**（此時 batch 間非原子，
  但因為舊資料保留且遷移可重入——下次仍會偵測到 subcollection 已非空而不重跑——
  最差情況是部分遷移，需在偵測條件上多加一道，見下）。
- **偵測條件必須可重入**：若用「subcollection 為空」當唯一條件，部分遷移成功後
  subcollection 非空，剩餘筆數就永遠不會被補上。
  對策：**遷移時同時把「舊 map 中有、subcollection 中沒有」的項目補齊**——
  也就是每次讀取都做一次 id 差集比對？不行，那等於每次都要讀舊 document，成本回頭。
  **採用的作法**：在 `favors/{uid}` 舊 document 上寫入一個標記欄位
  （例如 `_migratedAt`），遷移全部成功後才寫入。偵測條件改為「舊 document 存在
  且無 `_migratedAt`」。這樣部分失敗時標記不會寫入，下次讀取會重跑遷移；
  重複寫入同一筆 item 是冪等的（`set` 覆寫），**重跑無副作用**。
- 遷移拋錯時：以 `logger.e` 記錄，並**回退為直接使用舊 document 的資料**回傳給呼叫端
  （使用者仍看得到最愛，只是這次沒遷移成功），不向上拋錯讓畫面壞掉。這符合
  「錯誤處理不吞錯但也不讓使用者受害」的原則。

> **一句話**：舊資料在首次讀取時搬到新結構，搬完打標記，舊的留著不刪。任何一步失敗都不會讓使用者少掉一筆最愛。

### 決策 3：`fetchFavorsMap()` 的去留 — **改為 `fetchFavorIds()` 回傳 `Set<String>`，屬受控的 breaking change**

**採用：移除 `fetchFavorsMap()`，改為 `Future<Set<String>> fetchFavorIds()`。**

理由：

- **唯一消費端只用 `containsKey`**。`main_repo.dart:68` 的
  `favorsMap.containsKey(dto.id)` 完全不碰 value。保留 map 簽名，等於為了「介面契約穩定」
  這個抽象目標，強迫每次搜尋都把 N 筆 JSON 字串**反序列化後立刻丟棄**——
  純浪費，而且是在每次滑動載入更多時都發生。
- **改成 subcollection 後保留 map 簽名會更糟**。要湊出 map 就得讀完每筆 document 的完整內容；
  改成 id 集合則可以在查詢時只取 document id。這不只是省 CPU，也讓
  `main_repo` 的每次搜尋不必把整份最愛內容拉回來。
- **「Never break userspace」的 userspace 是誰？** 是**呼叫端的行為**，不是 method 的簽名字面。
  `FavorDataSource` 是 app 內部類別，沒有外部套件消費者，三個呼叫端全在本 repo 內、
  且只有一個真正用到這個 method。改完呼叫端後，**使用者可見行為零變化**——這不是破壞。
- 這是本計畫**唯一的 breaking change**，明確列出：
  - `Future<Map<String, dynamic>> fetchFavorsMap()` → `Future<Set<String>> fetchFavorIds()`
  - 影響檔案：`lib/data_layer/repositories/main_repo.dart:64,68`（`containsKey` → `contains`）
  - 影響測試：`test/guest_mode_test.dart:103-110`（`fetchFavorsMap` 的訪客測試改名對應）
  - **不影響**任何 UI、bloc、entity 或使用者可見行為。

> 附帶效益：`fetchFavorEntities()` 不再需要透過 `fetchFavorsMap()` 轉一手，
> 兩個 method 各自直接查詢自己需要的東西，`fetchFavorEntities` 內的
> 「先組 map 再拆 map」中間步驟消失。

### 決策 4：原子性確認

**確認：改成 `doc(restaurantId).set(...)` / `.delete()` 後即天然原子，不需 transaction、不需鎖、不需重試。**

- Firestore 保證**單一 document 的寫入是原子的**。`set()` 與 `delete()` 都是針對
  `favors/{uid}/items/{restaurantId}` 這一份 document 的整體操作。
- 收藏餐廳 A 與收藏餐廳 B 寫入**不同 document**，物理上無交錯可能，
  不論來自幾台裝置、間隔多短。**P2（lost update）從根本消失**，不是被緩解。
- 同一餐廳的重複翻轉（例如快速雙擊）仍是 last-write-wins，
  但收斂結果是「該餐廳的最終狀態」，**不會波及其他餐廳的資料**——與改版前
  「一次覆寫抹掉別人所有變更」是本質不同的嚴重度。
- `toggleFavor` 路徑中**不得再呼叫任何全量讀取**。這點寫進驗收條件 AC-2，
  並以測試守住（T5）。

### 決策 5：讀取成本 — **可接受，且是必要代價**

- `fetchFavorEntities()`：1 次 document read → 1 次 collection query 計 **N 筆** document read。
- `fetchFavorIds()`（`main_repo` 每次搜尋都呼叫）：同樣計 N 筆，
  但可用 `.get()` 後只取 `doc.id`，**不做任何 JSON 反序列化**，client 端 CPU 成本趨近於零。
- **量級評估**：個人最愛典型為數十至數百筆。Firestore 免費額度為每日 50,000 次 document read。
  即使一位使用者有 200 筆最愛、一天做 20 次搜尋，也只有 4,000 次讀取。
- **這是解除 1MB 上限必須付的代價**：把 N 筆資料拆成 N 份 document，讀取自然計 N 筆。
  想同時要「1 次 read」又要「無大小上限」是不可能的。
- **不做預先優化**：不加快取層、不加摘要 document、不做分頁。
  這些是「讀取成本真的成為瓶頸」時才存在的問題，現在不存在。
  若未來 `main_repo` 每次搜尋讀 N 筆真的痛，屆時再在 `MainRepo` 內快取一次 id 集合即可——
  那是一個獨立且更小的改動。

---

## 目標資料結構

```
favors/{uid}                                  ← 舊 document，遷移後保留不刪
  ├── "restaurant-id-A": "{...JSON 字串...}"     （舊資料，唯讀）
  └── "_migratedAt": Timestamp                  （遷移完成標記，新增）

favors/{uid}/items/{restaurantId}             ← 新 subcollection
  └── (document 內容 = YelpRestaurantSummaryDto.toJson() 的 Map)
```

**item document 的內容為 `Map<String, dynamic>`（結構化欄位），不是 JSON 字串。**
舊結構因為要塞進單一 document 的 map value 才被迫序列化成字串；
subcollection 沒有這個限制，直接存 `toDto.toJson()` 的 Map 更自然，
未來若要做「依評分排序最愛」之類的查詢也才有欄位可用。
遷移時對舊資料做一次 `jsonDecode` 即可轉換。

> `favor` 欄位在 DTO 上標了 `@JsonKey(includeFromJson: false, includeToJson: false)`，
> 本來就不會被序列化，讀回時一律設為 `true`——與現行 `fetchFavorEntities()` 的行為一致。

---

## 檔案異動清單

| 檔案 | 異動 |
| :--- | :--- |
| `lib/data_layer/datasources/favor_data_source.dart` | **主要**：資料結構改寫、遷移邏輯、`fetchFavorsMap` → `fetchFavorIds` |
| `lib/data_layer/repositories/main_repo.dart` | 呼叫端調整：`fetchFavorsMap().containsKey` → `fetchFavorIds().contains` |
| `test/guest_mode_test.dart` | 訪客測試對應改名（`fetchFavorsMap` → `fetchFavorIds`） |
| `test/favor_data_source_test.dart` | **新增**：本次的迴歸測試 |

**不動**：`favor_repo.dart`、`restaurant_detail_repo.dart`（只用 `toggleFavor`/`fetchFavorEntities`，簽名不變）、
`lib/di/injection.dart`（註冊方式不變）、`test/di_test.dart`（singleton 行為不變）。

---

## 任務拆分

> 標註格式：**複雜度等級**（機械性／整合／設計判斷）｜**寫入檔案 scope**
> 每個任務從測試開始（TDD-first），粒度控制在 2–5 分鐘。

---

### T1 — 建立 subcollection 存取的基礎：路徑 getter 與 `fetchFavorIds()`

- **複雜度**：整合（需理解 Firestore query API 與既有 uid guard）
- **寫入 scope**：`lib/data_layer/datasources/favor_data_source.dart`
- **可並行**：否（後續任務全部依賴此任務建立的 `_items` getter）

**步驟**：

1. 新增 subcollection 路徑常數與 getter，保留既有 `_doc`（遷移仍需要）：

```dart
static const String favorCollectionName = 'favors';
static const String itemsSubcollectionName = 'items';

DocumentReference get _doc =>
    FirebaseFirestore.instance.collection(favorCollectionName).doc(_uid);

CollectionReference get _items => _doc.collection(itemsSubcollectionName);
```

2. 新增 `fetchFavorIds()`，取代 `fetchFavorsMap()`。**保留空 uid guard**
   （AC-8：訪客不得觸碰 Firestore）：

```dart
/// 讀出所有最愛餐廳的 id 集合。
///
/// 只取 document id，不反序列化內容——主列表判斷「是否為最愛」只需要 id。
///
/// 未登入時（訪客或尚未登入）直接回傳空集合。少了這道 guard，
/// Firestore 會因空字串 doc id 拋出 [ArgumentError]——它繼承 [Error] 而非
/// [Exception]，呼叫端的 `on Exception` 接不住，會讓畫面卡在 loading。
Future<Set<String>> fetchFavorIds() async {
  if (_uid.isEmpty) {
    return <String>{};
  }

  await _migrateLegacyDocIfNeeded();

  QuerySnapshot snapshot = await _items.get();

  return snapshot.docs.map((doc) => doc.id).toSet();
}
```

3. **移除** `fetchFavorsMap()`。

**驗證**：`flutter analyze` 此時會因 `main_repo` 與測試引用不存在的 method 而報錯——**預期行為**，由 T3、T4 修復。

---

### T2 — 改寫 `toggleFavor()` 為單筆原子寫入

- **複雜度**：機械性（規格完整，直接替換）
- **寫入 scope**：`lib/data_layer/datasources/favor_data_source.dart`
- **可並行**：否（依賴 T1 的 `_items`）

**步驟**：把整段 read-modify-write 換成單筆寫入：

```dart
/// 翻轉 [summaryInfo] 的最愛狀態並寫回 Firestore。
///
/// 單筆 document 的寫入／刪除，Firestore 保證原子性——不需要讀出全量再覆寫，
/// 也就沒有多裝置併發互相覆蓋（lost update）的問題。
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
    await itemDoc.set(updatedEntity.toDto.toJson());
  } else {
    await itemDoc.delete();
  }

  return updatedEntity;
}
```

**關鍵檢查**：這個 method 內**不得出現**任何 `fetchFavorIds()`、`_doc.get()` 或
全量讀取。這是 AC-2 的核心。

---

### T3 — 改寫 `fetchFavorEntities()` 直接查 subcollection

- **複雜度**：機械性
- **寫入 scope**：`lib/data_layer/datasources/favor_data_source.dart`
- **可並行**：否（依賴 T1）

```dart
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
```

注意 uid guard 現在寫在自己身上（原本靠 `fetchFavorsMap()` 代勞），
AC-8 的第二個訪客測試仍成立。

---

### T4 — 實作 lazy migration（決策 2）

- **複雜度**：設計判斷（遷移的可重入性、失敗回退、批次上限都需要判斷）
- **寫入 scope**：`lib/data_layer/datasources/favor_data_source.dart`
- **可並行**：否（T1–T3 依賴此 method 存在才能通過 analyze）

**步驟**：

1. 新增遷移標記常數與 method：

```dart
static const String _migratedAtField = '_migratedAt';
static const int _batchLimit = 500; // Firestore WriteBatch 單批上限

/// 把舊的單一 document 結構搬到 subcollection，只在首次讀取時執行一次。
///
/// 舊結構為 `favors/{uid}` 一份 document，key 為餐廳 id、value 為序列化後的
/// JSON 字串。1MB 上限與全量覆寫的併發問題都源於此。
///
/// 遷移完成才寫入 [_migratedAtField] 標記；部分失敗時標記不會寫入，
/// 下次讀取會重跑——重複 set 同一筆是冪等的，重跑無副作用。
///
/// ponytail: 刻意不刪除舊 document。保留它才能在新版本出問題時退版回滾，
/// 也是遷移失敗時的真相來源。確認使用者全數升級後再另案清理。
Future<void> _migrateLegacyDocIfNeeded() async {
  try {
    DocumentSnapshot snapshot = await _doc.get();
    Map<String, dynamic>? legacy = snapshot.data() as Map<String, dynamic>?;

    // 沒有舊資料，或已遷移過 —— 直接結束
    if (legacy == null || legacy.containsKey(_migratedAtField)) {
      return;
    }

    Iterable<MapEntry<String, dynamic>> entries = legacy.entries.where(
      (e) => e.key != _migratedAtField,
    );

    for (List<MapEntry<String, dynamic>> chunk in _chunked(entries.toList())) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (MapEntry<String, dynamic> entry in chunk) {
        batch.set(
          _items.doc(entry.key),
          jsonDecode(entry.value as String) as Map<String, dynamic>,
        );
      }
      await batch.commit();
    }

    // 全部成功才打標記
    await _doc.set({
      _migratedAtField: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } on Exception catch (e, st) {
    // 遷移失敗不能讓最愛頁壞掉：舊資料仍完好，下次讀取會重試。
    logger.e('最愛資料遷移失敗，將於下次讀取重試', error: e, stackTrace: st);
  }
}

List<List<T>> _chunked<T>(List<T> items) => [
  for (int i = 0; i < items.length; i += _batchLimit)
    items.sublist(i, (i + _batchLimit).clamp(0, items.length)),
];
```

2. 確認 `logger` 已由 barrel import 可用（`main_repo.dart:79` 已在用同一個 logger，
   確認 `favor_data_source.dart` 的 import 是否涵蓋；若無則補上對應 barrel）。

**判斷點**：`_migrateLegacyDocIfNeeded()` 在每次讀取都會多打一次 `_doc.get()`。
遷移完成後這仍是**每次讀取一次額外 document read**。
若判定此成本不可接受，可在 instance 上加一個 `bool _migrationChecked` 快取
（singleton 生命週期內只查一次；uid 變更時需重置）。
**建議先不做**——一次 document read 相對 N 筆 query 是小數，
等真的量測到問題再加，並在該處留 `ponytail:` 註解說明。

---

### T5 — 更新 `main_repo` 呼叫端

- **複雜度**：機械性
- **寫入 scope**：`lib/data_layer/repositories/main_repo.dart`
- **可並行**：**可**（與 T6 測試檔並行，兩者不同檔案；但須等 T1 完成）

`main_repo.dart:64,68`：

```dart
Set<String> favorIds = await _favorDataSource.fetchFavorIds();

List<RestaurantEntity> fetchedEntities = (searchDto.businesses ?? []).map((
  dto,
) {
  bool isFavor = favorIds.contains(dto.id);
  return RestaurantEntity.fromDto(dto).copyWith(favor: isFavor);
}).toList();
```

**驗證**：`flutter analyze` 應回到 `No issues found!`（測試檔尚未改則仍有錯，見 T6）。

---

### T6 — 更新既有訪客迴歸測試

- **複雜度**：機械性
- **寫入 scope**：`test/guest_mode_test.dart`
- **可並行**：**可**（與 T5 並行）

`test/guest_mode_test.dart:103-110` 的第一個測試改為對應新 method：

```dart
test('fetchFavorIds returns empty without touching Firestore', () async {
  await resetManager(_Data.emptyPrefs);
  await SignInManager().markAsGuest();

  // 未初始化 Firebase：若 guard 失效，這裡會拋錯而非回傳空集合。
  expect(await FavorDataSource().fetchFavorIds(), isEmpty);
});
```

另外兩個測試（`fetchFavorEntities` 回空、`toggleFavor` 拋 `StateError`）
**不需修改**——但必須確認 T3 加上的 uid guard 讓第二個測試仍然通過
（訪客不會走到 `_migrateLegacyDocIfNeeded()`）。

**驗證**：`flutter test test/guest_mode_test.dart` 全綠。

---

### T7 — 新增「不做全量讀取」的迴歸測試

- **複雜度**：設計判斷（需決定在無 Firebase 環境下如何驗證寫入路徑）
- **寫入 scope**：`test/favor_data_source_test.dart`（新檔）
- **可並行**：否（依賴 T2 完成）

**目的**：守住 AC-2。本專案測試環境**未初始化 Firebase**，
無法直接斷言 Firestore 呼叫次數。因此採用**訪客路徑**作為可執行的守門：

```dart
group('FavorDataSource subcollection 寫入路徑', () {
  // 迴歸測試：toggleFavor 必須在任何 Firestore 存取「之前」就攔下訪客。
  // 舊實作先呼叫 fetchFavorsMap() 再 guard，路徑上多一次全量讀取；
  // 新實作是單筆原子寫入，guard 必須是第一件事。
  test('toggleFavor 在無 uid 時直接拋 StateError，不觸碰 Firestore', () async {
    await resetManager(_Data.emptyPrefs);
    await SignInManager().markAsGuest();

    // 未初始化 Firebase：若路徑中殘留任何讀取，會先拋 Firebase 相關錯誤
    // 而非 StateError，這個斷言就會失敗。
    expect(
      () => FavorDataSource().toggleFavor(const RestaurantEntity(id: 'any-id')),
      throwsStateError,
    );
  });
});
```

> **誠實標註**：這個測試無法證明「已登入時也不做全量讀取」——那需要
> `fake_cloud_firestore` 之類的新依賴，違反「不新增依賴」的約束。
> AC-2 在已登入路徑上由 **code review** 把關：`toggleFavor` 內不得出現
> `fetchFavorIds()` / `_doc.get()`。此限制在計畫中明示，不假裝測試涵蓋了。

**驗證**：`flutter test` 全綠。

---

### T8 — 全量驗證與安全規則提醒

- **複雜度**：機械性
- **寫入 scope**：無（僅執行指令）
- **可並行**：否（最終驗證）

```bash
flutter analyze
flutter test
```

- 預期：`No issues found!` 與測試全綠（含 `test/di_test.dart` 的 singleton 測試）。
- **輸出給使用者的行動項**（不可省略）：

  > 🔴 **部署前必做**：至 Firebase Console → Firestore Database → Rules，
  > 將既有 `match /favors/{uid}` 的規則擴充涵蓋子集合路徑
  > `favors/{uid}/items/{restaurantId}`。Firestore 規則**不會自動繼承到 subcollection**，
  > 未更新即上線會導致最愛功能全面 `permission-denied`。
  > 建議先在測試專案驗證規則後再發正式版。

---

## 任務相依與並行圖

```
T1 (基礎路徑 + fetchFavorIds)
 ├─→ T2 (toggleFavor 原子寫入) ──→ T7 (寫入路徑測試)
 ├─→ T3 (fetchFavorEntities)
 ├─→ T4 (lazy migration)          ← T1/T3 引用，實作可最後補但需同批完成
 ├─→ T5 (main_repo 呼叫端)  ┐
 └─→ T6 (guest_mode_test)   ┘ ← 這兩個可並行（不同檔案）
                                      ↓
                                 T8 (全量驗證)
```

- **並行機會**：只有 **T5 與 T6** 是真正安全的並行對（不同檔案、無共享狀態）。
- **T1–T4 全部寫入同一個檔案** `favor_data_source.dart`，**必須序列執行**，
  並行會造成寫入衝突。

---

## 執行方式選擇

| 方式 | 適用性 | 說明 |
| :--- | :---: | :--- |
| **單一 session 序列執行** | ✅ **建議** | T1–T4 集中在同一檔案且互相依賴，序列是自然選擇。T5/T6 的並行收益（兩個機械性小改動）不值得額外的協調成本。整體任務量小、檔案數少（4 個），單 session 一次做完最省。 |
| **Subagent-driven** | 🟡 可選 | 若要拆，建議切法為：agent A 負責 `favor_data_source.dart` 全部（T1–T4，設計判斷密集，需完整上下文），agent B 負責呼叫端與測試（T5–T7）。但 B 必須等 A 的簽名定案，實質仍是序列，收益有限。 |
| **Parallel session** | ❌ 不建議 | 核心變更集中於單一檔案，無法有效切分。多 session 會在 `favor_data_source.dart` 上互相覆寫。 |

> **建議**：單一 session 序列執行 T1 → T4（一口氣改完 `favor_data_source.dart`，
> 中途的 analyze 錯誤是預期的），再 T5/T6，最後 T7/T8。

---

## 不做的事（明確拒絕清單）

- ❌ 為 `FavorDataSource` 抽 interface — 只有一個實作，Ponytail 規則禁止。
- ❌ 加 repository 層的最愛快取 — 讀取成本目前不是瓶頸（決策 5）。
- ❌ 加 `addedAt` / `note` 欄位 — 無消費端，是留給未來的 scaffolding。
- ❌ 用 `runTransaction` 包 `toggleFavor` — 單筆 document 寫入已經原子，
  transaction 只會增加延遲與失敗率（決策 4）。
- ❌ 引入 `fake_cloud_firestore` 等測試依賴 — 違反「不新增依賴」，
  且 T7 已用既有手段守住主要迴歸點。
- ❌ 刪除舊 `favors/{uid}` document — 回滾保險，另案處理（決策 2）。
- ❌ 實作 `listId` 或 `saved_lists` 層 — 本次不做多套名單（決策 1）。
