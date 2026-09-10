import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';

import '../../domain/entities/ai_entities_barrel.dart';
import '../../domain/repositories/menu_vision_repository.dart';

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
      emit(const MenuVisionLoading());

      try {
        final A2UIComponent? result;
        if (event.source == ImageSource.camera) {
          result = await _repository.captureAndAnalyzeMenu();
        } else {
          result = await _repository.pickFromGalleryAndAnalyzeMenu();
        }

        if (result == null) {
          emit(const MenuVisionCancelled());
          return;
        }

        switch (result) {
          case DishCatalogComponent():
            emit(MenuVisionSuccess(catalog: result));
          case FallbackMarkdownComponent():
            emit(MenuVisionFailure(message: result.text));
        }
      } on Exception catch (e) {
        emit(MenuVisionFailure(message: '菜單辨識失敗：$e'));
      }
    });

    on<RetryMenuAnalysis>((event, emit) async {
      emit(const MenuVisionLoading());

      try {
        final result = await _repository.analyzeMenuImageBytes(
          event.imageBytes,
        );

        switch (result) {
          case DishCatalogComponent():
            emit(MenuVisionSuccess(catalog: result));
          case FallbackMarkdownComponent():
            emit(MenuVisionFailure(message: result.text));
        }
      } on Exception catch (e) {
        emit(MenuVisionFailure(message: '重試分析失敗：$e'));
      }
    });

    on<ResetMenuVision>((event, emit) {
      emit(const MenuVisionInitial());
    });
  }
}
