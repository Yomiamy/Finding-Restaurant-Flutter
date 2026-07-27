# 實作計畫：修復 Yelp API 分頁邏輯 Bug

## 檔案異動
- `lib/flow/main/repository/main_repository.dart`

## 資料結構與架構設計
- 不變更現有架構或資料結構。
- `MainRepository` 中的 `_offset` 變數將維持 `int` 類型，並依舊於 `reset()` 方法中歸零。
- 修改點在於 `fetchYelpSearchInfo` 中呼叫 API 後的 offset 更新方式：從錯誤的 `++this._offset` 修正為 `this._offset += MainRepository._MAX_ITEMS_COUNT_IN_LIST`。

## 任務拆分

### 任務 1：修復 `MainRepository` 的分頁 offset 更新邏輯
- **說明**：將 Yelp API 請求時的 offset 參數修正，並在請求成功後正確將 offset 加上每頁載入數量（limit）。
- **步驟**：
  1. 打開 `lib/flow/main/repository/main_repository.dart`。
  2. 在 `fetchYelpSearchInfo` 內，將 `apiInstance.businessesSearch` 呼叫的參數 `offset: ++this._offset` 替換為 `offset: this._offset`。
  3. 在 `apiInstance.businessesSearch` 呼叫結束並成功返回後（或在該方法適當的成功區段），加入 `this._offset += MainRepository._MAX_ITEMS_COUNT_IN_LIST;` 以遞增下次的分頁起始位置。
- **預計時間**：2 分鐘

### 任務 2：靜態分析與編譯檢查
- **說明**：確保修改沒有引入語法錯誤。
- **步驟**：
  1. 執行 `flutter analyze` 檢查潛在問題。
- **預計時間**：1 分鐘

## 執行方式
單一檔案、單一邏輯修改，將採用循序 (sequence) 的 Subagent-driven 或直接由主協調者 (Orchestrator) 單獨完成。不需要平行處理。
