# 修復 Yelp API 分頁邏輯 Bug

## What (做什麼)
修改 Yelp API 搜尋功能的分頁 (`offset`) 遞增邏輯，以確保分頁資料能正確載入。目前的實作中，每次請求分頁只將 `offset` 增加 1，這會導致極嚴重的資料重複與無法正確載入下一頁資料。正確的分頁邏輯應該是每次將 `offset` 增加每一頁的數量 (`limit`)。

## Why (為什麼做)
目前在 `MainRepository` 中，當觸發分頁時，傳給 Yelp API 的 offset 參數使用了 `++this._offset`。
Yelp API 的 `offset` 代表的是項目的起始位置。如果 `limit` 設為 50，下一頁的 `offset` 應該是 50，再下一頁是 100。
但目前邏輯會變成第一頁是 `offset=1`，第二頁是 `offset=2`，導致第二頁返回的結果有 49 筆是第一頁已經顯示過的資料，造成畫面出現大量重複的餐廳項目。

## 驗收條件 (Acceptance Criteria)
- [ ] 每次載入下一頁時，Yelp API 請求的 `offset` 應該正確增加 `_MAX_ITEMS_COUNT_IN_LIST` (50)。
- [ ] 第一頁的 `offset` 應為 0。
- [ ] 不再出現重複的餐廳資料載入。

## 範圍邊界 (Out of Scope)
- 暫不調整 Yelp API 其他查詢參數或重新設計搜尋邏輯。
- 不修改 UI 觸發分頁的方式。
