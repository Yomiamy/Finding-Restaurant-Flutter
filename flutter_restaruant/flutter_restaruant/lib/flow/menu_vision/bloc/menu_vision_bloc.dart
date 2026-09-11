import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';

part 'menu_vision_event.dart';
part 'menu_vision_state.dart';

/// 拍菜單 AI 視覺辨識 BLoC
///
/// 處理拍照分析、載入、成功與失敗狀態的單向資料流。
class MenuVisionBloc extends Bloc<MenuVisionEvent, MenuVisionState> {
  final MenuVisionRepository _repository;

  MenuVisionBloc({required MenuVisionRepository repository})
    : _repository = repository,
      super(const MenuVisionInitial()) {
    on<CaptureAndAnalyzeMenu>((event, emit) async {
      if (state is MenuVisionLoading) return;
      emit(const MenuVisionLoading());

      try {
        final Uint8List? imageBytes;
        if (event.source == ImageSource.camera) {
          imageBytes = await _repository.captureImage();
        } else {
          imageBytes = await _repository.pickImageFromGallery();
        }

        if (imageBytes == null) {
          emit(const MenuVisionCancelled());
          return;
        }

        final result = await _repository.analyzeMenuImageBytes(imageBytes);

        switch (result) {
          case DishCatalogComponent():
            emit(MenuVisionSuccess(catalog: result));
          case FallbackMarkdownComponent():
            emit(MenuVisionFailure(
              message: result.text,
              failedImageBytes: imageBytes,
            ));
        }
      } on Exception catch (e) {
        emit(MenuVisionFailure(message: '菜單辨識失敗：$e'));
      }
    });

    on<RetryMenuAnalysis>((event, emit) async {
      if (state is MenuVisionLoading) return;
      emit(const MenuVisionLoading());

      try {
        final result = await _repository.analyzeMenuImageBytes(
          event.imageBytes,
        );

        switch (result) {
          case DishCatalogComponent():
            emit(MenuVisionSuccess(catalog: result));
          case FallbackMarkdownComponent():
            emit(MenuVisionFailure(
              message: result.text,
              failedImageBytes: event.imageBytes,
            ));
        }
      } on Exception catch (e) {
        emit(MenuVisionFailure(
          message: '重試分析失敗：$e',
          failedImageBytes: event.imageBytes,
        ));
      }
    });

    on<ResetMenuVision>((event, emit) {
      emit(const MenuVisionInitial());
    });
  }
}
