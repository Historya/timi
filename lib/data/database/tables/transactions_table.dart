import 'package:drift/drift.dart';
import 'categories_table.dart';

class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(CategoriesTable, #id)();
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}