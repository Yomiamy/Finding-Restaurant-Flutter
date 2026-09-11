import 'dart:typed_data';

import '../entities/ai_entities_barrel.dart';

/// 拍菜單視覺辨識 Repository 抽象契約
abstract interface class MenuVisionRepository {
  /// 喚起相機拍照並取得圖片二進位資料
  ///
  /// 若使用者取消拍照，回傳 `null`。
  Future<Uint8List?> captureImage();

  /// 喚起相簿選取照片並取得圖片二進位資料
  ///
  /// 若使用者取消選取，回傳 `null`。
  Future<Uint8List?> pickImageFromGallery();

  /// 喚起相機拍照並進行菜單多模態分析
  ///
  /// 若使用者取消拍照，回傳 `null`。
  Future<A2UIComponent?> captureAndAnalyzeMenu();

  /// 喚起相簿選取照片並進行菜單多模態分析
  ///
  /// 若使用者取消選取，回傳 `null`。
  Future<A2UIComponent?> pickFromGalleryAndAnalyzeMenu();

  /// 直接分析傳入之圖片二進位資料
  Future<A2UIComponent> analyzeMenuImageBytes(Uint8List imageBytes);
}
