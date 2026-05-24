import 'package:drift/drift.dart';

class BudgetsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get period => text()();
  IntColumn get year => integer()();
  IntColumn get month => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}