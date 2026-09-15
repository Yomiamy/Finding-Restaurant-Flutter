import '../entities/entities_barrel.dart';

/// AI 覓食助理 Repository 抽象契約
abstract interface class AiFoodieRepository {
  /// 取得預設情境建議與歡迎訊息
  Future<List<AiFoodieMessage>> getInitialSuggestions();

  /// 發送使用者需求並取得結構化回應（包含自然語言與 GenUI 結構）
  Future<AiFoodieMessage> askAssistant(
    String prompt, {
    List<AiFoodieMessage>? history,
  });
}
