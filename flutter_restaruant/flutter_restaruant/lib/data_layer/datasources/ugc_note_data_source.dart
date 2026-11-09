import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../api/dto/ugc_note_dto.dart';
import '../../domain/entities/ugc_note_entity.dart';

/// 探店筆記在 Firestore (`ugc_notes`) 的唯讀資料來源。
class UgcNoteDataSource {
  static const String collectionName = 'ugc_notes';
  static const int defaultLimit = 40;

  final FirebaseFirestore? _firestoreOverride;
  final Logger _logger;

  UgcNoteDataSource({FirebaseFirestore? firestore, Logger? logger})
    : _firestoreOverride = firestore,
      _logger = logger ?? Logger();

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// 讀取探店筆記列表並依 `created_at_ms` 新到舊排序。
  ///
  /// 在記憶體內執行排序而非依賴 Firestore `.orderBy('created_at_ms')`，
  /// 避免人工建立種子文件時漏填 `created_at_ms` 導致整筆筆記被 Firestore 濾除。
  Future<List<UgcNoteEntity>> fetchNotes({int limit = defaultLimit}) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .limit(limit)
        .get();

    final notes = <UgcNoteEntity>[];
    for (final doc in snapshot.docs) {
      try {
        final raw = Map<String, dynamic>.from(doc.data());
        final createdAt = raw['created_at_ms'];
        if (createdAt is Timestamp) {
          raw['created_at_ms'] = createdAt.millisecondsSinceEpoch;
        } else if (createdAt is num) {
          raw['created_at_ms'] = createdAt.toInt();
        }
        final dto = UgcNoteDto.fromJson(raw);
        notes.add(UgcNoteEntity.fromDto(dto, docId: doc.id));
      } on TypeError catch (e, st) {
        _logger.w(
          'Skip malformed ugc_note ${doc.id}',
          error: e,
          stackTrace: st,
        );
      } on FormatException catch (e, st) {
        _logger.w(
          'Skip malformed ugc_note ${doc.id}',
          error: e,
          stackTrace: st,
        );
      }
    }

    notes.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return notes;
  }
}
