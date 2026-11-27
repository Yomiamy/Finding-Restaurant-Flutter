import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../api/dto/dto_barrel.dart';
import '../../domain/entities/entities_barrel.dart';
import '../../features/manager/manager_barrel.dart';

/// 共編美食地圖在 Cloud Firestore 的單一資料存取點。
///
/// 頂層集合為 `food_maps/{mapId}`，餐廳子集合為 `food_maps/{mapId}/items/{restaurantId}`，
/// 並以內部防枚舉索引 `food_map_invites/{inviteCode}` 對應 `map_id`。
class FoodMapDataSource {
  static const String mapsCollectionName = 'food_maps';
  static const String itemsSubcollectionName = 'items';
  static const String invitesCollectionName = 'food_map_invites';
  static const String inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int maxInviteCodeAttempts = 5;
  static const int _batchLimit = 500;
  static const int _importChunkSize = 400;
  static final RegExp _inviteCodePattern = RegExp(r'^[A-Z0-9]{8}$');

  final FirebaseFirestore? _firestoreOverride;
  final String Function()? _uidProvider;
  final String Function()? _displayNameProvider;
  final int Function()? _nowMsProvider;
  final Random _random;
  final Logger _logger;

  FoodMapDataSource({
    FirebaseFirestore? firestore,
    String Function()? uidProvider,
    String Function()? displayNameProvider,
    int Function()? nowMsProvider,
    Random? random,
    Logger? logger,
  }) : _firestoreOverride = firestore,
       _uidProvider = uidProvider,
       _displayNameProvider = displayNameProvider,
       _nowMsProvider = nowMsProvider,
       _random = random ?? Random.secure(),
       _logger = logger ?? Logger();

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _maps =>
      _firestore.collection(mapsCollectionName);

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection(invitesCollectionName);

  String get currentUid =>
      (_uidProvider?.call() ?? SignInManager().accountDto?.uid ?? '').trim();

  int get _nowMs =>
      _nowMsProvider?.call() ?? DateTime.now().millisecondsSinceEpoch;

  String _requireUid() {
    final uid = currentUid;
    if (uid.isEmpty) {
      throw StateError('FoodMap operation requires a signed-in user');
    }
    if (uid.contains('.')) {
      throw ArgumentError.value(uid, 'uid', 'UID must not contain "."');
    }
    return uid;
  }

  String _validateDocId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty ||
        trimmed.contains('/') ||
        trimmed == '.' ||
        trimmed == '..') {
      throw const FoodMapException(
        FoodMapErrorCode.invalidInput,
        'Invalid document ID',
      );
    }
    return trimmed;
  }

  String _resolveDisplayName(String uid) {
    final custom = _displayNameProvider?.call().trim() ?? '';
    if (custom.isNotEmpty) {
      return custom;
    }
    final account = SignInManager().accountDto?.account?.trim() ?? '';
    if (account.isNotEmpty) {
      final atIndex = account.indexOf('@');
      if (atIndex > 0) {
        return account.substring(0, atIndex);
      }
      return account;
    }
    if (uid.length >= 6) {
      return uid.substring(0, 6);
    }
    return uid.isNotEmpty ? uid : 'Member';
  }

  String _generateInviteCode() {
    final buffer = StringBuffer();
    for (int i = 0; i < FoodMapEntity.inviteCodeLength; i++) {
      buffer.write(inviteAlphabet[_random.nextInt(inviteAlphabet.length)]);
    }
    return buffer.toString();
  }

  Future<T> _guardFirestore<T>(
    Future<T> Function() action, {
    FoodMapErrorCode notFoundCode = FoodMapErrorCode.mapNotFound,
  }) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw FoodMapException(FoodMapErrorCode.permissionDenied, e.message);
        case 'not-found':
          throw FoodMapException(notFoundCode, e.message);
        default:
          throw FoodMapException(
            FoodMapErrorCode.unknown,
            '${e.code}: ${e.message}',
          );
      }
    }
  }

  Map<String, dynamic> _normalizeTimestamps(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    final raw = Map<String, dynamic>.from(source);
    for (final key in keys) {
      final value = raw[key];
      if (value is Timestamp) {
        raw[key] = value.millisecondsSinceEpoch;
      } else if (value is num) {
        raw[key] = value.toInt();
      }
    }
    return raw;
  }

  FoodMapEntity _parseMapSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw const FormatException('FoodMap document data is null');
    }
    final raw = _normalizeTimestamps(data, const [
      'created_at_ms',
      'updated_at_ms',
    ]);
    final dto = FoodMapDto.fromJson(raw);
    return FoodMapEntity.fromDto(dto, docId: doc.id);
  }

  FoodMapItemEntity _parseItemSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw const FormatException('FoodMapItem document data is null');
    }
    final raw = _normalizeTimestamps(data, const ['added_at_ms']);
    final dto = FoodMapItemDto.fromJson(raw);
    return FoodMapItemEntity.fromDto(dto, docId: doc.id);
  }

  /// 讀取目前使用者建立或加入的所有共編美食地圖，依 `updatedAtMs` 降冪排序。
  Future<List<FoodMapEntity>> fetchMyFoodMaps() async {
    final uid = currentUid;
    if (uid.isEmpty) {
      return <FoodMapEntity>[];
    }

    return _guardFirestore(() async {
      // ponytail: 個人共編地圖筆數天花板為數十筆，於記憶體排序免建 Firestore Composite Index；
      // 若日後單人超過數百張地圖，再補建 member_uids + updated_at_ms 複合索引並改分頁。
      final snapshot = await _maps
          .where('member_uids', arrayContains: uid)
          .get();

      final maps = <FoodMapEntity>[];
      for (final doc in snapshot.docs) {
        try {
          maps.add(_parseMapSnapshot(doc));
        } on TypeError catch (e, st) {
          _logger.w(
            'Skip malformed food_map ${doc.id}',
            error: e,
            stackTrace: st,
          );
        } on FormatException catch (e, st) {
          _logger.w(
            'Skip malformed food_map ${doc.id}',
            error: e,
            stackTrace: st,
          );
        }
      }

      maps.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
      return maps;
    });
  }

  /// 讀取指定共編地圖之最新資訊與所有餐廳項目（依 `addedAtMs` 降冪排序）。
  Future<({FoodMapEntity map, List<FoodMapItemEntity> items})>
  fetchFoodMapDetail(String mapId) async {
    final uid = _requireUid();
    final validMapId = _validateDocId(mapId);

    return _guardFirestore(() async {
      final mapRef = _maps.doc(validMapId);
      final mapSnap = await mapRef.get();
      if (!mapSnap.exists) {
        throw const FoodMapException(FoodMapErrorCode.mapNotFound);
      }

      final map = _parseMapSnapshot(mapSnap);
      if (!map.memberUids.contains(uid)) {
        throw const FoodMapException(FoodMapErrorCode.permissionDenied);
      }

      final itemsSnap = await mapRef.collection(itemsSubcollectionName).get();
      final items = <FoodMapItemEntity>[];
      for (final doc in itemsSnap.docs) {
        try {
          items.add(_parseItemSnapshot(doc));
        } on TypeError catch (e, st) {
          _logger.w(
            'Skip malformed food_map item ${doc.id}',
            error: e,
            stackTrace: st,
          );
        } on FormatException catch (e, st) {
          _logger.w(
            'Skip malformed food_map item ${doc.id}',
            error: e,
            stackTrace: st,
          );
        }
      }

      items.sort((a, b) => b.addedAtMs.compareTo(a.addedAtMs));
      return (map: map, items: items);
    });
  }

  /// 建立新的共編美食地圖，於同一 Transaction 內保證邀請碼不撞碼並寫入索引。
  Future<FoodMapEntity> createFoodMap({
    required String title,
    String description = '',
  }) async {
    final uid = _requireUid();
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();

    if (trimmedTitle.isEmpty ||
        trimmedTitle.length > FoodMapEntity.maxTitleLength ||
        trimmedDescription.length > FoodMapEntity.maxDescriptionLength) {
      throw const FoodMapException(
        FoodMapErrorCode.invalidInput,
        'Title or description length out of bounds',
      );
    }

    final displayName = _resolveDisplayName(uid);

    return _guardFirestore(() async {
      for (int attempt = 0; attempt < maxInviteCodeAttempts; attempt++) {
        final inviteCode = _generateInviteCode();
        final created = await _firestore.runTransaction<FoodMapEntity?>((
          tx,
        ) async {
          final inviteRef = _invites.doc(inviteCode);
          final inviteSnap = await tx.get(inviteRef);
          if (inviteSnap.exists) {
            return null;
          }

          final now = _nowMs;
          final mapRef = _maps.doc();
          final dto = FoodMapDto(
            title: trimmedTitle,
            description: trimmedDescription,
            ownerUid: uid,
            ownerName: displayName,
            inviteCode: inviteCode,
            memberUids: <String>[uid],
            memberNames: <String, String>{uid: displayName},
            itemCount: 0,
            createdAtMs: now,
            updatedAtMs: now,
          );

          tx.set(mapRef, dto.toJson());
          tx.set(inviteRef, <String, dynamic>{
            'map_id': mapRef.id,
            'owner_uid': uid,
          });

          return FoodMapEntity.fromDto(dto, docId: mapRef.id);
        });

        if (created != null) {
          return created;
        }
      }

      throw const FoodMapException(FoodMapErrorCode.inviteCodeGenerationFailed);
    });
  }

  /// 透過 8 碼邀請碼加入共編美食地圖；已是成員時不執行多餘寫入。
  Future<({FoodMapEntity map, bool alreadyMember})> joinFoodMapByInviteCode(
    String rawCode,
  ) async {
    final uid = _requireUid();
    final code = rawCode.trim().toUpperCase();
    if (!_inviteCodePattern.hasMatch(code)) {
      throw const FoodMapException(FoodMapErrorCode.invalidInviteCode);
    }

    final displayName = _resolveDisplayName(uid);

    return _guardFirestore(() async {
      final inviteSnap = await _invites.doc(code).get();
      if (!inviteSnap.exists) {
        throw const FoodMapException(FoodMapErrorCode.mapNotFound);
      }

      final rawMapId = inviteSnap.data()?['map_id'];
      if (rawMapId is! String) {
        throw const FoodMapException(FoodMapErrorCode.mapNotFound);
      }
      final mapId = rawMapId.trim();
      if (mapId.isEmpty ||
          mapId.contains('/') ||
          mapId == '.' ||
          mapId == '..') {
        throw const FoodMapException(FoodMapErrorCode.mapNotFound);
      }

      final mapRef = _maps.doc(mapId);
      return _firestore.runTransaction((tx) async {
        final mapSnap = await tx.get(mapRef);
        if (!mapSnap.exists) {
          throw const FoodMapException(FoodMapErrorCode.mapNotFound);
        }

        final existing = _parseMapSnapshot(mapSnap);
        if (existing.memberUids.contains(uid)) {
          return (map: existing, alreadyMember: true);
        }

        final now = _nowMs;
        final nextUids = List<String>.unmodifiable([
          ...existing.memberUids,
          uid,
        ]);
        final nextNames = Map<String, String>.unmodifiable({
          ...existing.memberNames,
          uid: displayName,
        });

        tx.update(mapRef, <String, dynamic>{
          'member_uids': nextUids,
          'member_names.$uid': displayName,
          'updated_at_ms': now,
        });

        return (
          map: existing.copyWith(
            memberUids: nextUids,
            memberNames: nextNames,
            updatedAtMs: now,
          ),
          alreadyMember: false,
        );
      });
    });
  }

  /// 刪除共編地圖（僅建立者可執行），先分批刪除所有餐廳子文件，再於獨立最終 batch 刪主文件與索引。
  Future<void> deleteFoodMap(String mapId) async {
    final uid = _requireUid();
    final validMapId = _validateDocId(mapId);

    return _guardFirestore(() async {
      final mapRef = _maps.doc(validMapId);
      final mapSnap = await mapRef.get();
      if (!mapSnap.exists) {
        throw const FoodMapException(FoodMapErrorCode.mapNotFound);
      }

      final map = _parseMapSnapshot(mapSnap);
      if (map.ownerUid != uid) {
        throw const FoodMapException(FoodMapErrorCode.permissionDenied);
      }

      final itemsSnap = await mapRef.collection(itemsSubcollectionName).get();
      final docs = itemsSnap.docs;
      for (int i = 0; i < docs.length; i += _batchLimit) {
        final batch = _firestore.batch();
        for (final doc in docs.skip(i).take(_batchLimit)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 獨立最終 WriteBatch（至多 2 筆），避免 items 筆數為 499/500 倍數時超過 500 上限。
      final finalBatch = _firestore.batch();
      finalBatch.delete(mapRef);
      if (_inviteCodePattern.hasMatch(map.inviteCode)) {
        finalBatch.delete(_invites.doc(map.inviteCode));
      }
      await finalBatch.commit();
    });
  }

  /// 一般成員退出共編地圖（建立者不可退出，僅可刪除地圖）。
  Future<void> leaveFoodMap(String mapId) async {
    final uid = _requireUid();
    final validMapId = _validateDocId(mapId);

    return _guardFirestore(() async {
      final mapRef = _maps.doc(validMapId);
      await _firestore.runTransaction((tx) async {
        final mapSnap = await tx.get(mapRef);
        if (!mapSnap.exists) {
          throw const FoodMapException(FoodMapErrorCode.mapNotFound);
        }

        final map = _parseMapSnapshot(mapSnap);
        if (!map.memberUids.contains(uid) || map.ownerUid == uid) {
          throw const FoodMapException(FoodMapErrorCode.permissionDenied);
        }

        tx.update(mapRef, <String, dynamic>{
          'member_uids': FieldValue.arrayRemove(<String>[uid]),
          'member_names.$uid': FieldValue.delete(),
          'updated_at_ms': _nowMs,
        });
      });
    });
  }

  /// 將單筆餐廳加入共編地圖；若餐廳已存在則不重複寫入亦不遞增 `item_count`。
  Future<({bool added, FoodMapItemEntity item})> addRestaurant({
    required String mapId,
    required RestaurantEntity restaurant,
    String note = '',
  }) async {
    final uid = _requireUid();
    final validMapId = _validateDocId(mapId);
    final validRestaurantId = _validateDocId(restaurant.id ?? '');
    final trimmedNote = note.trim();
    if (trimmedNote.length > FoodMapItemEntity.maxNoteLength) {
      throw const FoodMapException(
        FoodMapErrorCode.invalidInput,
        'Note exceeds maximum length',
      );
    }

    final displayName = _resolveDisplayName(uid);
    final normalizedRestaurant = restaurant.copyWith(id: validRestaurantId);

    return _guardFirestore(() async {
      final mapRef = _maps.doc(validMapId);
      final itemRef = mapRef
          .collection(itemsSubcollectionName)
          .doc(validRestaurantId);

      return _firestore.runTransaction((tx) async {
        final mapSnap = await tx.get(mapRef);
        if (!mapSnap.exists) {
          throw const FoodMapException(FoodMapErrorCode.mapNotFound);
        }

        final map = _parseMapSnapshot(mapSnap);
        if (!map.memberUids.contains(uid)) {
          throw const FoodMapException(FoodMapErrorCode.permissionDenied);
        }

        final itemSnap = await tx.get(itemRef);
        if (itemSnap.exists) {
          return (added: false, item: _parseItemSnapshot(itemSnap));
        }

        final now = _nowMs;
        final dto = FoodMapItemDto(
          restaurant: normalizedRestaurant.toDto,
          addedByUid: uid,
          addedByName: displayName,
          note: trimmedNote,
          addedAtMs: now,
          votes: const <String, int>{},
        );

        tx.set(itemRef, dto.toJson());
        tx.update(mapRef, <String, dynamic>{
          'item_count': map.itemCount + 1,
          'updated_at_ms': now,
        });

        return (
          added: true,
          item: FoodMapItemEntity.fromDto(dto, docId: validRestaurantId),
        );
      });
    });
  }

  /// 批次將餐廳匯入共編地圖，採嚴格 Read-Before-Write 分批 Transaction 防止重複與重試灌水。
  Future<({int addedCount, int skippedCount})> importRestaurants({
    required String mapId,
    required List<RestaurantEntity> restaurants,
  }) async {
    final uid = _requireUid();
    final validMapId = _validateDocId(mapId);

    if (restaurants.isEmpty) {
      return (addedCount: 0, skippedCount: 0);
    }

    final deduped = <({String id, RestaurantEntity restaurant})>[];
    final seenIds = <String>{};
    int initialSkipped = 0;

    for (final restaurant in restaurants) {
      final rawId = (restaurant.id ?? '').trim();
      final isInvalid =
          rawId.isEmpty || rawId.contains('/') || rawId == '.' || rawId == '..';
      if (isInvalid || !seenIds.add(rawId)) {
        initialSkipped++;
        continue;
      }
      deduped.add((id: rawId, restaurant: restaurant.copyWith(id: rawId)));
    }

    if (deduped.isEmpty) {
      return (addedCount: 0, skippedCount: initialSkipped);
    }

    final displayName = _resolveDisplayName(uid);
    final mapRef = _maps.doc(validMapId);
    final itemsCol = mapRef.collection(itemsSubcollectionName);

    return _guardFirestore(() async {
      int totalAdded = 0;
      int totalSkipped = initialSkipped;

      for (int i = 0; i < deduped.length; i += _importChunkSize) {
        final chunk = deduped.skip(i).take(_importChunkSize).toList();
        final chunkResult = await _firestore
            .runTransaction<({int added, int skipped})>((tx) async {
              // Phase 1：純讀取（Transaction 強制 Read-Before-Write）
              final mapSnap = await tx.get(mapRef);
              if (!mapSnap.exists) {
                throw const FoodMapException(FoodMapErrorCode.mapNotFound);
              }
              final map = _parseMapSnapshot(mapSnap);
              if (!map.memberUids.contains(uid)) {
                throw const FoodMapException(FoodMapErrorCode.permissionDenied);
              }

              final toInsert = <({String id, RestaurantEntity restaurant})>[];
              int chunkSkipped = 0;
              for (final entry in chunk) {
                final itemSnap = await tx.get(itemsCol.doc(entry.id));
                if (itemSnap.exists) {
                  chunkSkipped++;
                } else {
                  toInsert.add(entry);
                }
              }

              // Phase 2：純寫入
              if (toInsert.isEmpty) {
                return (added: 0, skipped: chunkSkipped);
              }

              final now = _nowMs;
              for (final entry in toInsert) {
                final dto = FoodMapItemDto(
                  restaurant: entry.restaurant.toDto,
                  addedByUid: uid,
                  addedByName: displayName,
                  note: '',
                  addedAtMs: now,
                  votes: const <String, int>{},
                );
                tx.set(itemsCol.doc(entry.id), dto.toJson());
              }
              tx.update(mapRef, <String, dynamic>{
                'item_count': map.itemCount + toInsert.length,
                'updated_at_ms': now,
              });

              return (added: toInsert.length, skipped: chunkSkipped);
            });

        totalAdded += chunkResult.added;
        totalSkipped += chunkResult.skipped;
      }

      return (addedCount: totalAdded, skippedCount: totalSkipped);
    });
  }

  /// 移除地圖內指定餐廳（僅限現任成員且為地圖建立者或原推薦人）。
  Future<void> removeRestaurant({
    required String mapId,
    required String restaurantId,
  }) async {
    final uid = _requireUid();
    final validMapId = _validateDocId(mapId);
    final validRestaurantId = _validateDocId(restaurantId);

    return _guardFirestore(() async {
      final mapRef = _maps.doc(validMapId);
      final itemRef = mapRef
          .collection(itemsSubcollectionName)
          .doc(validRestaurantId);

      await _firestore.runTransaction((tx) async {
        final mapSnap = await tx.get(mapRef);
        if (!mapSnap.exists) {
          throw const FoodMapException(FoodMapErrorCode.mapNotFound);
        }
        final map = _parseMapSnapshot(mapSnap);
        if (!map.memberUids.contains(uid)) {
          throw const FoodMapException(FoodMapErrorCode.permissionDenied);
        }

        final itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) {
          return;
        }

        final rawAddedBy = itemSnap.data()?['added_by_uid'];
        final addedByUid = rawAddedBy is String ? rawAddedBy.trim() : '';
        if (map.ownerUid != uid && addedByUid != uid) {
          throw const FoodMapException(FoodMapErrorCode.permissionDenied);
        }

        final nextCount = map.itemCount > 0 ? map.itemCount - 1 : 0;
        tx.delete(itemRef);
        tx.update(mapRef, <String, dynamic>{
          'item_count': nextCount,
          'updated_at_ms': _nowMs,
        });
      });
    });
  }

  /// 更新指定餐廳之私房推薦短評（僅限現任成員且為地圖建立者或原推薦人）。
  Future<FoodMapItemEntity> updateItemNote({
    required String mapId,
    required String restaurantId,
    required String note,
  }) async {
    final uid = _requireUid();
    final validMapId = _validateDocId(mapId);
    final validRestaurantId = _validateDocId(restaurantId);
    final trimmedNote = note.trim();
    if (trimmedNote.length > FoodMapItemEntity.maxNoteLength) {
      throw const FoodMapException(
        FoodMapErrorCode.invalidInput,
        'Note exceeds maximum length',
      );
    }

    return _guardFirestore(() async {
      final mapRef = _maps.doc(validMapId);
      final itemRef = mapRef
          .collection(itemsSubcollectionName)
          .doc(validRestaurantId);

      return _firestore.runTransaction((tx) async {
        final mapSnap = await tx.get(mapRef);
        if (!mapSnap.exists) {
          throw const FoodMapException(FoodMapErrorCode.mapNotFound);
        }
        final map = _parseMapSnapshot(mapSnap);
        if (!map.memberUids.contains(uid)) {
          throw const FoodMapException(FoodMapErrorCode.permissionDenied);
        }

        final itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) {
          throw const FoodMapException(FoodMapErrorCode.itemNotFound);
        }

        final existing = _parseItemSnapshot(itemSnap);
        if (!existing.canModify(uid, mapOwnerUid: map.ownerUid)) {
          throw const FoodMapException(FoodMapErrorCode.permissionDenied);
        }

        tx.update(itemRef, <String, dynamic>{'note': trimmedNote});
        tx.update(mapRef, <String, dynamic>{'updated_at_ms': _nowMs});

        return existing.copyWith(note: trimmedNote);
      });
    });
  }

  /// 對指定餐廳進行單鍵原子投票（`votes.<uid>`），不同成員併發投票互不覆蓋。
  Future<void> setVote({
    required String mapId,
    required String restaurantId,
    required FoodMapVote vote,
  }) async {
    final uid = _requireUid();
    final validMapId = _validateDocId(mapId);
    final validRestaurantId = _validateDocId(restaurantId);

    return _guardFirestore(() async {
      final itemRef = _maps
          .doc(validMapId)
          .collection(itemsSubcollectionName)
          .doc(validRestaurantId);
      final Object value = vote == FoodMapVote.none
          ? FieldValue.delete()
          : vote.rawValue;
      await itemRef.update(<String, dynamic>{'votes.$uid': value});
    }, notFoundCode: FoodMapErrorCode.itemNotFound);
  }
}
