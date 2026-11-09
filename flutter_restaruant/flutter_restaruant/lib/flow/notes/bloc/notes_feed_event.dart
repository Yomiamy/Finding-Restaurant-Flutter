import 'package:equatable/equatable.dart';

sealed class NotesFeedEvent extends Equatable {
  const NotesFeedEvent();

  @override
  List<Object?> get props => [];
}

final class FetchNotesFeed extends NotesFeedEvent {
  const FetchNotesFeed();
}
