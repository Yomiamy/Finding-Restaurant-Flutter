# 功能規格：Firestore 最愛改用 Subcollection

- **來源**：`docs/brainstorm/2026-08-18_features_brainstorm.md` §1.2 缺陷 4、§F-2.1（第一階段）
- **產出日期**：2026-08-18
- **類型**：技術債修復（架構缺陷），非使用者可見的新功能
- **優先級**：P1

---

## What & Why

### 使用者故事

> 作為一位長期使用者，當我的最愛餐廳累積到數百間時，我希望「加入最愛」依然能成功寫入，
> 而不是某天突然靜默失敗、或看起來成功了但重開 App 又不見。

> 作為同時在手機與平板登入同一帳號的使用者，我希望在 A 裝置收藏的餐廳，
> 不會因為我在 B 裝置也收藏了另一間而被覆蓋消失。

### 問題現況（實查於 2026-08-18）

`lib/data_layer/datasources/favor_data_source.dart` 目前的資料結構為：

```
favors/{uid}                      ← 單一 document
  ├── "restaurant-id-A": "{...序列化的 YelpRestaurantSummaryDto JSON 字串...}"
  ├── "restaurant-id-B": "{...}"
  └── ...
```

`toggleFavor()` 的實作是典型的 **read-modify-write**：

1. `fetchFavorsMap()` — 讀出**全量**最愛 map
2. 在記憶體中 `favorsMap[id] = ...` 或 `favorsMap.remove(id)` 改**一筆**
3. `_doc.set(favorsMap, SetOptions(merge: false))` — 把全量 map **整份覆寫**回去

由此衍生兩個**真實存在**的問題（非臆想）：

| # | 問題 | 觸發條件 | 後果 |
| :-: | :--- | :--- | :--- |
| **P1** | Firestore 單一 document 硬上限 **1 MiB** | 每筆 summary JSON 含 `name`/`imageUrl`/`categories`/`location`/`coordinates`，估算約 0.5–1 KB。累積約 **1000–2000 筆**即撞牆 | 寫入被 Firestore 拒絕，`toggleFavor` 拋錯。且因為是**全量覆寫**，一旦撞牆，**連刪除既有最愛都做不到**——使用者被鎖死在無法自救的狀態 |
| **P2** | read-modify-write **非原子**（lost update） | 多裝置同時操作；或單裝置快速連點兩個不同餐廳的最愛按鈕，兩個 `toggleFavor` 的 read 與 write 交錯 | 後寫入者以自己讀到的舊快照整份覆寫，**先寫入者的變更無聲消失**。使用者看到收藏成功的 toast，重開 App 卻不見 |

**P2 的嚴重性高於 P1**：P1 需要極端使用量才觸發，P2 在日常快速連點就可能發生，且**完全沒有錯誤訊息**——是靜默資料遺失。

### 為什麼 subcollection 能一次解掉兩者

改成一筆最愛 = 一份 document 後：

- **P1 消失**：1 MiB 上限變成「單筆餐廳資料」的上限，而非「全部最愛」的上限。單筆 ~1 KB 距離 1 MiB 有三個數量級的餘裕。collection 本身無筆數上限。
- **P2 消失**：`doc(restaurantId).set(...)` 與 `doc(restaurantId).delete()` 都是**針對單一 document 的整體寫入**，Firestore 保證單 document 寫入的原子性。不同餐廳寫不同 document，天然無交錯；同一餐廳的重複操作則由 last-write-wins 收斂到一致結果（而非互相抹除**其他**餐廳的資料）。

這是 Linus 式的「好品味」解法：**不是加鎖、不是加 transaction、不是加重試**——是換一個資料結構，讓特殊情況根本不存在。

---

## 驗收條件

### 功能正確性

- **AC-1**：新增最愛後，Firestore 於 `favors/{uid}/items/{restaurantId}` 產生一份 document；取消最愛後該 document 被刪除。**不再有任何全量覆寫寫入**。
- **AC-2**：`toggleFavor()` 對單一餐廳的寫入為**原子操作**——實作僅使用 `doc(restaurantId).set()` 或 `doc(restaurantId).delete()`，路徑中**不得存在**「先讀全量、再寫全量」的步驟。可由 code review 驗證。
- **AC-3**：收藏餐廳 A 的同時（或期間）收藏餐廳 B，兩者**皆能保留**，不互相覆蓋。
- **AC-4**：最愛頁（`FavorRepo.fetchFavorInfos(false)`）顯示的清單內容與改版前一致，`favor` 一律為 `true`。
- **AC-5**：主列表（`MainRepo.fetchYelpSearchInfo`）的最愛標記正確——已收藏的餐廳顯示為已收藏。

### 相容性（Never break userspace）

- **AC-6**：既有使用者的舊 `favors/{uid}` document 中的最愛，**升級後仍看得到**，不得憑空消失。遷移策略見實作計畫。
- **AC-7**：三個消費端 repository（`main_repo` / `favor_repo` / `restaurant_detail_repo`）的**對外行為不變**。若 `FavorDataSource` 的 method 簽名有調整，須同步改完所有呼叫端且行為等價。
- **AC-8**：訪客三個迴歸行為維持不變——`test/guest_mode_test.dart:99-126`：
  - 未登入時讀取最愛回傳空集合，**不觸碰 Firestore**（空字串 doc id 會拋 `ArgumentError`，繼承 `Error` 而非 `Exception`，呼叫端的 `on Exception` 接不住，會讓畫面卡在 loading）
  - 未登入時 `toggleFavor` 拋 `StateError`
- **AC-9**：`test/di_test.dart:50` 的 `FavorDataSource` 共享 singleton 行為不變。

### 品質

- **AC-10**：`flutter analyze` 維持 `No issues found!`。
- **AC-11**：既有測試全綠；新增針對「單筆寫入路徑不做全量讀取」的測試。

---

## 範圍邊界

### 做

- `FavorDataSource` 的資料結構由單一 document map 改為 subcollection
- 對應調整三個消費端 repository 的呼叫（若簽名變動）
- 舊資料的相容處理（詳見實作計畫的遷移決策）
- 對應的單元測試

### 不做（YAGNI）

- ❌ **多套口袋名單（saved_lists）UI 與資料模型**：F-2.1 的完整願景是
  `users/{uid}/saved_lists/{listId}/items/{restaurantId}`，支援「深夜私房名單」「週五酒吧清單」等多套名單。
  **本次只解缺陷 4（1MB 上限 + 併發覆寫）**，不做名單管理 UI、不做 `listId` 概念。
  路徑設計須保證未來可平滑升級（見實作計畫的路徑決策）。
- ❌ **F-2.2 社群共編 / 公開名單**：完全獨立的後續功能。
- ❌ **`addedAt` / `note` 欄位**：F-2.1 提到的附加欄位，目前無任何 UI 消費，
  加了就是「留給未來的 scaffolding」。等真的要做排序或筆記時再加。
- ❌ **即時同步（snapshot listener）**：現況是 pull-based 的一次性讀取，本次不改變讀取模型。
- ❌ **離線快取策略調整**：`cloud_firestore` 的預設離線持久化行為不動。
- ❌ **分頁讀取最愛清單**：目前最愛頁一次載入全部。在使用者最愛量真的變成瓶頸前不做。

### Out of scope — 需使用者手動處理

- 🔴 **Firestore 安全規則（Security Rules）**：本 repo **不存在** `firestore.rules` 檔案，
  規則由 Firebase Console 直接管理，**無法在此 repo 內完成變更**。

  > **⚠️ 使用者行動項**：部署本次變更前，須至 Firebase Console →
  > Firestore Database → Rules，將既有針對 `favors/{uid}` 的規則
  > **擴充至涵蓋 subcollection 路徑** `favors/{uid}/items/{restaurantId}`。
  >
  > Firestore 規則**不會自動繼承到 subcollection**——父 document 的 `match` 區塊
  > 若未使用遞迴萬用字元 `{document=**}`，子集合的讀寫會被預設拒絕。
  > 這代表：**規則沒改就上線，所有最愛功能會全面失效（permission-denied）**。
  > 這是本次變更最高的上線風險。

---

## 已知風險

| 風險 | 等級 | 說明與對策 |
| :--- | :---: | :--- |
| **安全規則未同步更新** | 🔴 | 上線即全面 permission-denied。對策：列為使用者行動項（見上），並在實作計畫的驗證步驟中要求先在測試環境確認規則後再發版。 |
| **舊資料遷移失敗導致最愛「消失」** | 🔴 | 使用者最愛是有情感價值的資料，消失＝重大事故。對策：採用**不刪除舊 document** 的遷移策略（見實作計畫），任何時刻都能回滾。 |
| **讀取成本上升** | 🟡 | `fetchFavorEntities()` 從 1 次 document read 變成 N 次 document read（Firestore 依**回傳筆數**計費，collection query 算 N 筆）。以個人最愛量級（數十至數百筆）與 Firestore 免費額度（每日 50K reads）評估，**代價可接受**，且這正是解除 1MB 上限必須付出的成本。若未來成為瓶頸，再以「摘要 document + subcollection」的混合結構優化——但那是**現在不存在的問題**。 |
| **`main_repo` 每次搜尋都讀一次最愛** | 🟡 | 既有行為（`main_repo.dart:64` 每次 `fetchYelpSearchInfo` 都呼叫一次），改版後讀取筆數放大。對策：本次以「只讀 id、不讀完整 document」的方式壓低成本（見實作計畫）。不引入快取層——那是另一個問題。 |
| **舊版 App 與新版並存期間的資料分裂** | 🟢 | 舊版 App 只寫舊 document、新版只寫 subcollection，過渡期兩者可能不一致。對策：遷移策略保留舊 document，且新版讀取時會合併舊資料，使用者體感上不遺失。強制更新非必要。 |
