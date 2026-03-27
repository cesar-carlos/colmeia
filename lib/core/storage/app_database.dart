import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

@DriftDatabase(tables: <Type>[CacheEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> putCacheValue({
    required String key,
    required String value,
  }) {
    return into(cacheEntries).insertOnConflictUpdate(
      CacheEntriesCompanion(
        key: Value<String>(key),
        value: Value<String>(value),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  Future<String?> getCacheValue(String key) async {
    final entry =
        await (select(cacheEntries)..where((table) {
              return table.key.equals(key);
            }))
            .getSingleOrNull();

    return entry?.value;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'colmeia.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
