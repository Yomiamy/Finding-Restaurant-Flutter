import 'package:equatable/equatable.dart';

import '../../../domain/entities/ugc_note_entity.dart';

sealed class NotesFeedState extends Equatable {
  const NotesFeedState();

  @override
  List<Object?> get props => [];
}

final class NotesFeedInitial extends NotesFeedState {
  const NotesFeedInitial();
}

final class NotesFeedLoading extends NotesFeedState {
  const NotesFeedLoading();
}

final class NotesFeedSuccess extends NotesFeedState {
  final List<UgcNoteEntity> notes;

  const NotesFeedSuccess({required this.notes});

  @override
  List<Object?> get props => [notes];
}

final class NotesFeedEmpty extends NotesFeedState {
  const NotesFeedEmpty();
}

final class NotesFeedFailure extends NotesFeedState {
  final String message;

  const NotesFeedFailure(this.message);

  @override
  List<Object?> get props => [message];
}
