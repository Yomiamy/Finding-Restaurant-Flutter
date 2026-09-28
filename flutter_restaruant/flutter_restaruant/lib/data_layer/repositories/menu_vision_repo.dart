import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/entities_barrel.dart';
import '../../domain/repositories/menu_vision_repository.dart';
import '../datasources/ai_model_config.dart';
import 'menu_analysis_schema.dart';

/// 菜單圖片分析函式簽章 (便於測試與自定義替換)
typedef MenuAnalyzerFunction = Future<String> Function(Uint8List imageBytes);

/// 拍菜單多模態分析 Repository 實作
class MenuVisionRepo implements MenuVisionRepository {
  MenuVisionRepo({
    ImagePicker? picker,
    FirebaseAI? firebaseAI,
    MenuAnalyzerFunction? analyzer,
    AiModelConfig? modelConfig,
  }) : _picker = picker ?? ImagePicker(),
       _firebaseAI = firebaseAI,
       _analyzer = analyzer,
       _modelConfig = modelConfig ?? AiModelConfig();

  final ImagePicker _picker;
  final FirebaseAI? _firebaseAI;
  final MenuAnalyzerFunction? _analyzer;
  final AiModelConfig _modelConfig;

  GenerativeModel _getModel() {
    final ai = _firebaseAI ?? FirebaseAI.googleAI();
    return ai.generativeModel(
      model: _modelConfig.menuVisionModel,
      systemInstruction: Content.system(
        _modelConfig.menuVisionSystemInstruction,
      ),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: menuAnalysisSchema,
      ),
    );
  }

  @override
  Future<Uint8List?> captureImage() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1500,
      maxHeight: 1500,
      imageQuality: 85,
    );
    if (xFile == null) return null;
    return xFile.readAsBytes();
  }

  @override
  Future<Uint8List?> pickImageFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1500,
      maxHeight: 1500,
      imageQuality: 85,
    );
    if (xFile == null) return null;
    return xFile.readAsBytes();
  }

  @override
  Future<A2UIComponent?> captureAndAnalyzeMenu() async {
    final imageBytes = await captureImage();
    if (imageBytes == null) return null;
    return analyzeMenuImageBytes(imageBytes);
  }

  @override
  Future<A2UIComponent?> pickFromGalleryAndAnalyzeMenu() async {
    final imageBytes = await pickImageFromGallery();
    if (imageBytes == null) return null;
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
    final rawJson = await _analyze(imageBytes);
    if (rawJson == null || rawJson.trim().isEmpty) {
      throw const FormatException('Empty menu analysis response');
    }

    final decoded = switch (jsonDecode(rawJson)) {
      final Map<String, Object?> m => m,
      final v => throw FormatException(
        'Menu analysis response is not a JSON object',
        v,
      ),
    };
    return A2UIComponent.fromJson({
      'component_type': 'dish_catalog',
      'data': decoded,
    });
  }

  Future<String?> _analyze(Uint8List imageBytes) async {
    if (_analyzer != null) return _analyzer(imageBytes);

    final prompt = [
      Content.multi([
        const TextPart('請完整拆解這張菜單的菜色、價格與過敏原資訊。'),
        InlineDataPart(_detectMimeType(imageBytes), imageBytes),
      ]),
    ];
    final response = await _getModel().generateContent(prompt);
    return response.text;
  }
}
