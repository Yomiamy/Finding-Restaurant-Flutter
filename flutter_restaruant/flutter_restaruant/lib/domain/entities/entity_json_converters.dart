/// 手寫 `whereType` 語意：null 維持 null，型別不符的元素靜默丟棄。
List<String>? stringListFromJson(List<Object?>? raw) =>
    raw?.whereType<String>().toList(growable: false);

List<T>? mapListFromJson<T>(
  List<Object?>? raw,
  T Function(Map<String, Object?> json) fromJson,
) => raw
    ?.whereType<Map<String, Object?>>()
    .map(fromJson)
    .toList(growable: false);
