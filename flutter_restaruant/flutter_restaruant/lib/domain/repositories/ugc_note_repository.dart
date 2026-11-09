import '../entities/ugc_note_entity.dart';

/// 探店筆記領域儲存庫契約。
abstract class UgcNoteRepository {
  Future<List<UgcNoteEntity>> fetchNotes();
}
