# 實作計畫：F-2.3 雙排瀑布流 UGC 食記與 15 秒探店短影片

> 項目編號：**F-2.3**  
> 建立日期：2026-11-09  
> 關聯規格：[`docs/features/2026-11-09-ugc-notes-feed.md`](../features/2026-11-09-ugc-notes-feed.md)  
> 實查基線：`main`  
> 狀態：草稿（等待 STAGE 0b plan-verifier 初審與使用者確認）

---

## 1. 目標與架構設計

建立唯讀的「探店筆記」社群內容瀏覽流，由側邊選單（`DrawerWidget`）進入獨立的 `NotesFeedPage`（`MasonryGridView` 雙排瀑布流），點擊卡片後進入 `NoteDetailPage`（支援多圖 `PageView` 輪播或 15 秒短影片 `video_player` 播放）。

資料流向（單向 Clean Architecture）：
`Firestore (ugc_notes)` → `UgcNoteDataSource` → `UgcNoteDto` → `UgcNoteEntity` → `UgcNoteRepository` (`UgcNoteRepo`) → `NotesFeedBloc` → `NotesFeedPage` → `NoteDetailPage`。

---

## 2. 任務切分與依賴關係

| 任務編號 | 負責範圍 | 異動檔案 | 執行方式 |
|:---|:---|:---|:---:|
| **T1** | 相依套件、多國語系、DTO / Entity / DataSource / Repository 與 DI | `pubspec.yaml`<br>`lib/l10n/intl_zh_TW.arb`、`lib/l10n/intl_en.arb`<br>`lib/generated/**`<br>`lib/api/dto/ugc_note_dto.dart` (`.g.dart`)<br>`lib/domain/entities/ugc_note_entity.dart`<br>`lib/data_layer/datasources/ugc_note_data_source.dart`<br>`lib/domain/repositories/ugc_note_repository.dart`<br>`lib/data_layer/repositories/ugc_note_repo.dart`<br>`lib/app/di/injection.dart`<br>`test/data_layer/ugc_note_repo_test.dart`<br>`test/di_test.dart` | 序列第一步 |
| **T2** | `NotesFeedBloc` 狀態管理與單元測試 | `lib/flow/notes/bloc/notes_feed_event.dart`<br>`lib/flow/notes/bloc/notes_feed_state.dart`<br>`lib/flow/notes/bloc/notes_feed_bloc.dart`<br>`lib/flow/notes/bloc/notes_feed_barrel.dart`<br>`test/flow/notes/notes_feed_bloc_test.dart` | 序列第二步（依賴 T1 Domain 層） |
| **T3** | `NotesFeedPage` 雙排瀑布流、`NoteDetailPage` 詳情頁與 Drawer / 路由整合 | `lib/flow/notes/view/notes_feed_page.dart`<br>`lib/flow/notes/view/note_detail_page.dart`<br>`lib/flow/notes/view/view_barrel.dart`<br>`lib/flow/notes/notes_barrel.dart`<br>`lib/flow/main/view/drawer_widget.dart`<br>`lib/flow/main/view/main_page.dart`<br>`lib/app/routes/routes_table.dart`<br>`test/flow/notes/notes_feed_page_test.dart`<br>`test/flow/notes/note_detail_page_test.dart`<br>`test/flow/main/view/drawer_widget_test.dart` | 序列第三步（依賴 T2 BLoC 層） |

---

## 3. 詳細設計與具體程式碼

### 3.1 T1：相依套件、語系、DTO、Entity、DataSource、Repository 與 DI

#### 3.1.1 `pubspec.yaml`
新增：
```yaml
  flutter_staggered_grid_view: ^0.7.0 # 雙排瀑布流佈局 (Masonry Grid)
  video_player: ^2.14.1 # 官方短影片播放器
```

#### 3.1.2 多國語系 (`lib/l10n/intl_zh_TW.arb` & `lib/l10n/intl_en.arb`)
新增鍵值：
- `notes_feed_title`: `"探店筆記"` / `"Foodie Notes"`
- `notes_feed_empty`: `"尚無探店筆記"` / `"No foodie notes yet"`
- `note_detail_title`: `"筆記詳情"` / `"Note Detail"`
- `note_video_error`: `"影片載入失敗"` / `"Failed to load video"`

#### 3.1.3 `lib/api/dto/ugc_note_dto.dart`
遵循專案規範（`@JsonSerializable()` + `Equatable`）：
```dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ugc_note_dto.g.dart';

@JsonSerializable()
class UgcNoteDto extends Equatable {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'content')
  final String? content;

  @JsonKey(name: 'author_name')
  final String? authorName;

  @JsonKey(name: 'author_avatar_url')
  final String? authorAvatarUrl;

  @JsonKey(name: 'media_type')
  final String? mediaType;

  @JsonKey(name: 'cover_url')
  final String? coverUrl;

  @JsonKey(name: 'cover_aspect_ratio')
  final double? coverAspectRatio;

  @JsonKey(name: 'image_urls')
  final List<String>? imageUrls;

  @JsonKey(name: 'video_url')
  final String? videoUrl;

  @JsonKey(name: 'video_duration_sec')
  final int? videoDurationSec;

  @JsonKey(name: 'restaurant_name')
  final String? restaurantName;

  @JsonKey(name: 'created_at_ms')
  final int? createdAtMs;

  const UgcNoteDto({
    this.id,
    this.title,
    this.content,
    this.authorName,
    this.authorAvatarUrl,
    this.mediaType,
    this.coverUrl,
    this.coverAspectRatio,
    this.imageUrls,
    this.videoUrl,
    this.videoDurationSec,
    this.restaurantName,
    this.createdAtMs,
  });

  factory UgcNoteDto.fromJson(Map<String, dynamic> json) =>
      _$UgcNoteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UgcNoteDtoToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    authorName,
    authorAvatarUrl,
    mediaType,
    coverUrl,
    coverAspectRatio,
    imageUrls,
    videoUrl,
    videoDurationSec,
    restaurantName,
    createdAtMs,
  ];
}
```

#### 3.1.4 `lib/domain/entities/ugc_note_entity.dart`
消滅所有邊界情況（null 欄位、`coverAspectRatio` 極端值、影片秒數超界）：
```dart
import 'package:equatable/equatable.dart';

import '../../api/dto/ugc_note_dto.dart';

class UgcNoteEntity extends Equatable {
  static const double defaultAspectRatio = 0.8;
  static const double minAspectRatio = 0.6;
  static const double maxAspectRatio = 1.5;
  static const int maxVideoDurationSec = 15;

  final String id;
  final String title;
  final String content;
  final String authorName;
  final String authorAvatarUrl;
  final bool isVideo;
  final String coverUrl;
  final double coverAspectRatio;
  final List<String> imageUrls;
  final String videoUrl;
  final int videoDurationSec;
  final String restaurantName;
  final int createdAtMs;

  const UgcNoteEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.isVideo,
    required this.coverUrl,
    required this.coverAspectRatio,
    required this.imageUrls,
    required this.videoUrl,
    required this.videoDurationSec,
    required this.restaurantName,
    required this.createdAtMs,
  });

  factory UgcNoteEntity.fromDto(UgcNoteDto dto, {String? docId}) {
    final rawRatio = dto.coverAspectRatio ?? defaultAspectRatio;
    final safeRatio = rawRatio.isNaN || rawRatio.isInfinite || rawRatio <= 0
        ? defaultAspectRatio
        : rawRatio.clamp(minAspectRatio, maxAspectRatio);

    final rawImages = (dto.imageUrls ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final primaryCover = (dto.coverUrl?.trim().isNotEmpty ?? false)
        ? dto.coverUrl!.trim()
        : (rawImages.isNotEmpty ? rawImages.first : '');
    final normalizedImages =
        rawImages.isNotEmpty ? rawImages : (primaryCover.isNotEmpty ? [primaryCover] : const <String>[]);

    final videoUrl = dto.videoUrl?.trim() ?? '';
    final isVideo = dto.mediaType == 'video' && videoUrl.isNotEmpty;
    final rawDuration = dto.videoDurationSec ?? maxVideoDurationSec;
    final safeDuration = rawDuration.clamp(1, maxVideoDurationSec);

    return UgcNoteEntity(
      id: (dto.id?.trim().isNotEmpty ?? false) ? dto.id!.trim() : (docId ?? ''),
      title: dto.title?.trim() ?? '',
      content: dto.content?.trim() ?? '',
      authorName: dto.authorName?.trim() ?? '',
      authorAvatarUrl: dto.authorAvatarUrl?.trim() ?? '',
      isVideo: isVideo,
      coverUrl: primaryCover,
      coverAspectRatio: safeRatio,
      imageUrls: normalizedImages,
      videoUrl: videoUrl,
      videoDurationSec: safeDuration,
      restaurantName: dto.restaurantName?.trim() ?? '',
      createdAtMs: dto.createdAtMs ?? 0,
    );
  }

  String get formattedVideoDuration {
    final secs = videoDurationSec.clamp(1, maxVideoDurationSec);
    return '0:${secs.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    authorName,
    authorAvatarUrl,
    isVideo,
    coverUrl,
    coverAspectRatio,
    imageUrls,
    videoUrl,
    videoDurationSec,
    restaurantName,
    createdAtMs,
  ];
}
```

#### 3.1.5 `lib/data_layer/datasources/ugc_note_data_source.dart`
比照 `FavorDataSource` 採 lazy getter 取得 `FirebaseFirestore.instance`（確保 `di_test.dart` 在未初始化 Firebase 時不會拋錯），並兼容 `Timestamp` 與 `int`：
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../api/dto/ugc_note_dto.dart';
import '../../domain/entities/ugc_note_entity.dart';

class UgcNoteDataSource {
  static const String collectionName = 'ugc_notes';
  static const int defaultLimit = 40;

  final FirebaseFirestore? _firestoreOverride;

  UgcNoteDataSource({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Future<List<UgcNoteEntity>> fetchNotes({int limit = defaultLimit}) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .limit(limit)
        .get();

    final notes = snapshot.docs.map((doc) {
      final raw = Map<String, dynamic>.from(doc.data());
      final createdAt = raw['created_at_ms'];
      if (createdAt is Timestamp) {
        raw['created_at_ms'] = createdAt.millisecondsSinceEpoch;
      } else if (createdAt is num) {
        raw['created_at_ms'] = createdAt.toInt();
      }
      final dto = UgcNoteDto.fromJson(raw);
      return UgcNoteEntity.fromDto(dto, docId: doc.id);
    }).toList();

    notes.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return notes;
  }
}
```
> **為什麼在記憶體內排序 (`notes.sort`) 而非強制 `.orderBy('created_at_ms')`？**
> Firestore 的 `.orderBy('created_at_ms')` 會直接濾掉所有缺少 `created_at_ms` 欄位的種子文件！人工在 Firebase Console 新增種子資料時常漏填時間戳，拉回 `limit(40)` 後於記憶體內依 `createdAtMs` 降冪排序（缺值預設為 `0` 排最後），能消滅「Console 漏填一個欄位整篇筆記消失」的特殊情況。

#### 3.1.6 `UgcNoteRepository` & `UgcNoteRepo` & DI
- `lib/domain/repositories/ugc_note_repository.dart`:
  ```dart
  abstract class UgcNoteRepository {
    Future<List<UgcNoteEntity>> fetchNotes();
  }
  ```
- `lib/data_layer/repositories/ugc_note_repo.dart`:
  ```dart
  class UgcNoteRepo implements UgcNoteRepository {
    final UgcNoteDataSource _dataSource;

    UgcNoteRepo({UgcNoteDataSource? dataSource})
      : _dataSource = dataSource ?? UgcNoteDataSource();

    @override
    Future<List<UgcNoteEntity>> fetchNotes() => _dataSource.fetchNotes();
  }
  ```
- `lib/app/di/injection.dart`:
  註冊 `UgcNoteDataSource` 與 `UgcNoteRepository`。

---

### 3.2 T2：`NotesFeedBloc` 狀態管理 (`lib/flow/notes/bloc/`)

- **Events (`notes_feed_event.dart`)**：
  - `sealed class NotesFeedEvent extends Equatable`
  - `final class FetchNotesFeed extends NotesFeedEvent`
- **States (`notes_feed_state.dart`)**：
  - `sealed class NotesFeedState extends Equatable`
  - `final class NotesFeedInitial extends NotesFeedState`
  - `final class NotesFeedLoading extends NotesFeedState`
  - `final class NotesFeedSuccess extends NotesFeedState` (`final List<UgcNoteEntity> notes`)
  - `final class NotesFeedEmpty extends NotesFeedState`
  - `final class NotesFeedFailure extends NotesFeedState` (`final String message`)
- **BLoC (`notes_feed_bloc.dart`)**：
  - 處理 `FetchNotesFeed`：發出 `NotesFeedLoading()` → 呼叫 `_repository.fetchNotes()` → 空列表發 `NotesFeedEmpty()`，非空發 `NotesFeedSuccess(notes: notes)`；捕捉 `on Exception catch (e, st)` 記錄 `Logger` 並發 `NotesFeedFailure`。

---

### 3.3 T3：`NotesFeedPage` 雙排瀑布流、`NoteDetailPage` 詳情頁與 Drawer / 路由串接

#### 3.3.1 `lib/flow/notes/view/notes_feed_page.dart`
- `static const routeName = '/NotesFeedPage';`
- 使用 `BlocBuilder<NotesFeedBloc, NotesFeedState>` 窮盡式 `switch (state)`：
  - `NotesFeedInitial()` / `NotesFeedLoading()`：`const LoadingWidget()`
  - `NotesFeedEmpty()`：`EmptyDataWidget(title: S.current.notes_feed_empty, subtitle: '')`
  - `NotesFeedFailure()`：`EmptyDataWidget.withDefaults(onRetry: () => _bloc.add(const FetchNotesFeed()))`
  - `NotesFeedSuccess(:final notes)`：`RefreshIndicator` 包覆 `MasonryGridView.count(crossAxisCount: 2, mainAxisSpacing: ThemeSize.space10, crossAxisSpacing: ThemeSize.space10, padding: const EdgeInsets.all(ThemeSize.space10), itemCount: notes.length, itemBuilder: ...)`。
- 提取獨立元件 `class NoteMasonryCard extends StatelessWidget`（遵守 Style Guide 禁止 `_buildSubWidget` 輔助方法）：
  - 頂部 `AspectRatio(aspectRatio: note.coverAspectRatio)` 顯示封面圖（空 URL 或載入錯誤回退至 `Assets.images.empty` 佔位圖）。
  - 若 `note.isVideo == true`，右上角疊加半透明黑底膠囊，內含 `Icon(Icons.play_arrow, size: ThemeSize.size16, color: ThemeColor.colorffffff)` 與 `Text(note.formattedVideoDuration)`。
  - 下方顯示 `note.title`（`maxLines: 2`）、`note.restaurantName`（若有，附 `Icons.place` 小圖示）與 `note.authorName`。
  - 點擊卡片呼叫 `Navigator.of(context).pushNamed(NoteDetailPage.routeName, arguments: note)`。

#### 3.3.2 `lib/flow/notes/view/note_detail_page.dart`
- `static const routeName = '/NoteDetailPage';`
- 於 `didChangeDependencies()`（搭配 `_isInit` 旗標，遵守 Style Guide §7.7 嚴禁在 `build` 指派路由參數給狀態）讀取 `ModalRoute.of(context)?.settings.arguments as UgcNoteEntity`（同時支援建構子直接傳入 `UgcNoteEntity? initialNote` 便於測試）。
- 媒體區塊拆分為兩個獨立 StatefulWidget：
  1. `NoteImageCarousel`（當 `!note.isVideo`）：以 `PageView.builder` 支援多圖左右滑動，底部置中顯示頁碼膠囊（如 `1 / 3`）。
  2. `NoteVideoPlayer`（當 `note.isVideo`）：
     - 在 `initState` 以 `VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))` 初始化並設定 `setLooping(true)`。
     - 在 `dispose()` 確實呼叫 `_controller.dispose()`。
     - 初始化完成時渲染 `AspectRatio` + `VideoPlayer(_controller)` + `VideoProgressIndicator` + 點擊切換播放／暫停覆蓋層。
     - 若初始化拋出異常（例如測試環境無原生 VideoPlayer channel 或網路失敗），捕捉錯誤並渲染帶播放圖示與秒數標示的降級視覺面板（`Key('note_video_fallback')`），確保在單元／Widget 測試及不支援平台上永不崩潰。

#### 3.3.3 `DrawerWidget`、`MainPage` 與 `routes_table.dart`
- `DrawerWidget` 新增 `required this.onNotesFeed` 回呼與「探店筆記」`ListTile`（圖示 `Icons.explore`）。
- `MainPage` 新增 `_navigateToNotesFeed()` 呼叫 `Navigator.of(context).pushNamed(NotesFeedPage.routeName)`。
- `routes_table.dart` 註冊 `NotesFeedPage.routeName`（包裹 `BlocProvider<NotesFeedBloc>`）與 `NoteDetailPage.routeName`。

---

## 4. 驗證計畫

1. `dart run build_runner build --delete-conflicting-outputs` 產出 `ugc_note_dto.g.dart`。
2. `dart run intl_utils:generate` 產出多國語系檔案。
3. 執行 `flutter test test/data_layer/ugc_note_repo_test.dart test/flow/notes/ test/flow/main/view/drawer_widget_test.dart test/di_test.dart`。
4. 執行全套 `flutter test` 與 `flutter analyze .`，確保 0 issues 且全數測試通過。
