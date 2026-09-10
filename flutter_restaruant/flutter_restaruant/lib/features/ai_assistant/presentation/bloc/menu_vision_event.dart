part of 'menu_vision_bloc.dart';

@immutable
abstract class MenuVisionEvent extends Equatable {
  const MenuVisionEvent();

  @override
  List<Object?> get props => [];
}

/// 喚起相機或相簿拍攝/選取菜單並分析
class CaptureAndAnalyzeMenu extends MenuVisionEvent {
  final ImageSource source;

  const CaptureAndAnalyzeMenu({this.source = ImageSource.camera});

  @override
  List<Object?> get props => [source];
}

/// 以既有圖片位元組重新分析（重試用）
class RetryMenuAnalysis extends MenuVisionEvent {
  final Uint8List imageBytes;

  const RetryMenuAnalysis({required this.imageBytes});

  @override
  List<Object?> get props => [imageBytes];
}

/// 重置為初始狀態
class ResetMenuVision extends MenuVisionEvent {
  const ResetMenuVision();
}
