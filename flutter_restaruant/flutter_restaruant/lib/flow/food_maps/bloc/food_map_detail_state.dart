import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities_barrel.dart';

sealed class FoodMapDetailFeedback extends Equatable {
  final int nonce;

  const FoodMapDetailFeedback(this.nonce);

  @override
  List<Object?> get props => [nonce];
}

final class FoodMapNoteUpdatedFeedback extends FoodMapDetailFeedback {
  const FoodMapNoteUpdatedFeedback(super.nonce);
}

final class FoodMapItemRemovedFeedback extends FoodMapDetailFeedback {
  const FoodMapItemRemovedFeedback(super.nonce);
}

final class FoodMapDetailActionErrorFeedback extends FoodMapDetailFeedback {
  final FoodMapErrorCode errorCode;

  const FoodMapDetailActionErrorFeedback(this.errorCode, super.nonce);

  @override
  List<Object?> get props => [errorCode, nonce];
}

sealed class FoodMapDetailState extends Equatable {
  const FoodMapDetailState();

  @override
  List<Object?> get props => [];
}

final class FoodMapDetailInitial extends FoodMapDetailState {
  const FoodMapDetailInitial();
}

final class FoodMapDetailLoading extends FoodMapDetailState {
  final FoodMapEntity? initialMap;

  const FoodMapDetailLoading({this.initialMap});

  @override
  List<Object?> get props => [initialMap];
}

final class FoodMapDetailLoaded extends FoodMapDetailState {
  final FoodMapEntity map;
  final List<FoodMapItemEntity> items;
  final String currentUid;
  final FoodMapDetailFeedback? feedback;

  const FoodMapDetailLoaded({
    required this.map,
    required this.items,
    required this.currentUid,
    this.feedback,
  });

  FoodMapDetailLoaded copyWith({
    FoodMapEntity? map,
    List<FoodMapItemEntity>? items,
    String? currentUid,
    FoodMapDetailFeedback? feedback,
    bool clearFeedback = false,
  }) {
    return FoodMapDetailLoaded(
      map: map ?? this.map,
      items: items ?? this.items,
      currentUid: currentUid ?? this.currentUid,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
    );
  }

  @override
  List<Object?> get props => [map, items, currentUid, feedback];
}

final class FoodMapDetailFailure extends FoodMapDetailState {
  final FoodMapEntity? initialMap;
  final FoodMapErrorCode errorCode;

  const FoodMapDetailFailure({this.initialMap, required this.errorCode});

  @override
  List<Object?> get props => [initialMap, errorCode];
}
