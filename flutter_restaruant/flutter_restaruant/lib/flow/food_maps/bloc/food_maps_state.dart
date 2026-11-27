import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities_barrel.dart';

sealed class FoodMapsFeedback extends Equatable {
  final int nonce;

  const FoodMapsFeedback(this.nonce);

  @override
  List<Object?> get props => [nonce];
}

final class FoodMapCreatedFeedback extends FoodMapsFeedback {
  final FoodMapEntity map;

  const FoodMapCreatedFeedback(this.map, super.nonce);

  @override
  List<Object?> get props => [map, nonce];
}

final class FoodMapJoinedFeedback extends FoodMapsFeedback {
  final FoodMapEntity map;
  final bool alreadyMember;

  const FoodMapJoinedFeedback({
    required this.map,
    required this.alreadyMember,
    required int nonce,
  }) : super(nonce);

  @override
  List<Object?> get props => [map, alreadyMember, nonce];
}

final class FoodMapDeletedFeedback extends FoodMapsFeedback {
  const FoodMapDeletedFeedback(super.nonce);
}

final class FoodMapLeftFeedback extends FoodMapsFeedback {
  const FoodMapLeftFeedback(super.nonce);
}

final class FoodMapsActionErrorFeedback extends FoodMapsFeedback {
  final FoodMapErrorCode errorCode;

  const FoodMapsActionErrorFeedback(this.errorCode, super.nonce);

  @override
  List<Object?> get props => [errorCode, nonce];
}

sealed class FoodMapsState extends Equatable {
  const FoodMapsState();

  @override
  List<Object?> get props => [];
}

final class FoodMapsInitial extends FoodMapsState {
  const FoodMapsInitial();
}

final class FoodMapsLoading extends FoodMapsState {
  const FoodMapsLoading();
}

final class FoodMapsLoaded extends FoodMapsState {
  final List<FoodMapEntity> maps;
  final String currentUid;
  final bool isSubmitting;
  final FoodMapsFeedback? feedback;

  const FoodMapsLoaded({
    required this.maps,
    required this.currentUid,
    this.isSubmitting = false,
    this.feedback,
  });

  FoodMapsLoaded copyWith({
    List<FoodMapEntity>? maps,
    String? currentUid,
    bool? isSubmitting,
    FoodMapsFeedback? feedback,
    bool clearFeedback = false,
  }) {
    return FoodMapsLoaded(
      maps: maps ?? this.maps,
      currentUid: currentUid ?? this.currentUid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
    );
  }

  @override
  List<Object?> get props => [maps, currentUid, isSubmitting, feedback];
}

final class FoodMapsFailure extends FoodMapsState {
  final FoodMapErrorCode errorCode;

  const FoodMapsFailure({required this.errorCode});

  @override
  List<Object?> get props => [errorCode];
}
