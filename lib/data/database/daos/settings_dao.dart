import 'package:drift/drift.dart';
import '../app_database.dart';

class SettingsDao {
  final AppDatabase _db;
  SettingsDao(this._db);

  Future<String?> get(String key) async {
    final rows = await (_db.select(_db.settingsTable)
      ..where((s) => s.key.equals(key))
    ).get();
    return rows.isEmpty ? null : rows.first.value;
  }

  Future<void> set(String key, String value) async {
    final existing = await get(key);
    if (existing != null) {
      await (_db.update(_db.settingsTable)
        ..where((s) => s.key.equals(key))
      ).write(SettingsTableCompanion(value: Value(value)));
    } else {
      await _db.into(_db.settingsTable).insert(
        SettingsTableCompanion(key: Value(key), value: Value(value)),
      );
    }
  }
}