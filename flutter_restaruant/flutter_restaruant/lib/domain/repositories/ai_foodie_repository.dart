import '../entities/entities_barrel.dart';

/// AI 覓食助理 Repository 抽象契約
abstract interface class AiFoodieRepository {
  /// 取得預設情境建議與歡迎訊息
  Future<List<AiFoodieMessage>> getInitialSuggestions();

  /// 發送使用者需求並取得結構化回應（包含自然語言與 GenUI 結構）
  /// [candidateRestaurants] 可傳入首頁已加載的周邊真實餐廳列表，作為 AI 推薦與比對的接地 (Grounding) 依據
  Future<AiFoodieMessage> askAssistant(
    String prompt, {
    List<AiFoodieMessage>? history,
    List<RestaurantEntity>? candidateRestaurants,
  });
}
