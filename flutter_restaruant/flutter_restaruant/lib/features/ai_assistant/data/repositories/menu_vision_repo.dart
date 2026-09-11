import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/ai_entities_barrel.dart';
import '../../domain/repositories/menu_vision_repository.dart';
import 'menu_analysis_schema.dart';

/// 菜單圖片分析函式簽章 (便於測試與自定義替換)
typedef MenuAnalyzerFunction = Future<String> Function(Uint8List imageBytes);

/// 拍菜單多模態分析 Repository 實作
class MenuVisionRepo implements MenuVisionRepository {
  MenuVisionRepo({
    ImagePicker? picker,
    FirebaseAI? firebaseAI,
    MenuAnalyzerFunction? analyzer,
  })  : _picker = picker ?? ImagePicker(),
        _firebaseAI = firebaseAI,
        _analyzer = analyzer;

  final ImagePicker _picker;
  final FirebaseAI? _firebaseAI;
  final MenuAnalyzerFunction? _analyzer;

  static const String systemInstruction = '''
你是一位資深星級主廚與食品安全檢驗專家。請仔細審視傳入的菜單照片：
1. 辨識所有可識別菜色名稱與價格。
2. 進行成分拆解，明確標註是否有致敏成分 (包含堅果、花生、蛋、牛奶、小麥麩質、甲殼類海鮮、大豆)。
3. 一律依據定義的 JSON Schema 輸出純 JSON，不可有任何額外的對話或說明。
''';

  GenerativeModel _getModel() {
    final ai = _firebaseAI ?? FirebaseAI.googleAI();
    return ai.generativeModel(
      model: 'gemini-3.5-flash-lite',
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: menuAnalysisSchema,
      ),
    );
  }

  @override
  Future<A2UIComponent?> captureAndAnalyzeMenu() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1500,
      maxHeight: 1500,
      imageQuality: 85,
    );

    if (xFile == null) return null;
    final imageBytes = await xFile.readAsBytes();
    return analyzeMenuImageBytes(imageBytes);
  }

  @override
  Future<A2UIComponent?> pickFromGalleryAndAnalyzeMenu() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1500,
      maxHeight: 1500,
      imageQuality: 85,
    );

    if (xFile == null) return null;
    final imageBytes = await xFile.readAsBytes();
    return analyzeMenuImageBytes(imageBytes);
  }

  static String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'image/jpeg';
  }

  @override
  Future<A2UIComponent> analyzeMenuImageBytes(Uint8List imageBytes) async {
    try {
      final String? rawJson;
      if (_analyzer != null) {
        rawJson = await _analyzer(imageBytes);
      } else {
        final model = _getModel();
        final mimeType = _detectMimeType(imageBytes);
        final prompt = [
          Content.multi([
            const TextPart('請完整拆解這張菜單的菜色、價格與過敏原資訊。'),
            InlineDataPart(mimeType, imageBytes),
          ]),
        ];

        final response = await model.generateContent(prompt);
        rawJson = response.text;
      }

      if (rawJson == null || rawJson.trim().isEmpty) {
        return const FallbackMarkdownComponent(text: '未能取得菜單辨識結果，請重試。');
      }

      final decoded = jsonDecode(rawJson) as Map<String, Object?>;
      return A2UIComponent.fromJson({
        'component_type': 'dish_catalog',
        'data': decoded,
      });
    } on Exception catch (e) {
      return FallbackMarkdownComponent(
        text: '菜單辨識異常，請確認照片清晰度後重試 ($e)',
      );
    }
  }
}
