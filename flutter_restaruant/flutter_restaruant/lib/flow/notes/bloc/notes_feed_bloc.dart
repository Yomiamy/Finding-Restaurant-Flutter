import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../domain/repositories/ugc_note_repository.dart';
import 'notes_feed_event.dart';
import 'notes_feed_state.dart';

/// 管理探店筆記雙排瀑布流載入狀態的 BLoC。
class NotesFeedBloc extends Bloc<NotesFeedEvent, NotesFeedState> {
  final UgcNoteRepository _repository;
  final Logger _logger;

  NotesFeedBloc({
    required UgcNoteRepository repository,
    Logger? logger,
  }) : _repository = repository,
       _logger = logger ?? Logger(),
       super(const NotesFeedInitial()) {
    on<FetchNotesFeed>(_onFetchNotesFeed);
  }

  Future<void> _onFetchNotesFeed(
    FetchNotesFeed event,
    Emitter<NotesFeedState> emit,
  ) async {
    emit(const NotesFeedLoading());
    try {
      final notes = await _repository.fetchNotes();
      if (notes.isEmpty) {
        emit(const NotesFeedEmpty());
      } else {
        emit(NotesFeedSuccess(notes: notes));
      }
    } on Exception catch (e, st) {
      _logger.e('FetchNotesFeed failed', error: e, stackTrace: st);
      emit(NotesFeedFailure(e.toString()));
    }
  }
}
