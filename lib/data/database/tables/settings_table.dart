import 'package:drift/drift.dart';

class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
}