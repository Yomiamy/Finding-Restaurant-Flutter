import '../../domain/entities/ugc_note_entity.dart';
import '../../domain/repositories/ugc_note_repository.dart';
import '../datasources/ugc_note_data_source.dart';

class UgcNoteRepo implements UgcNoteRepository {
  final UgcNoteDataSource _dataSource;

  UgcNoteRepo({UgcNoteDataSource? dataSource})
    : _dataSource = dataSource ?? UgcNoteDataSource();

  @override
  Future<List<UgcNoteEntity>> fetchNotes() => _dataSource.fetchNotes();
}
