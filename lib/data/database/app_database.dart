import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'tables/categories_table.dart';
import 'tables/transactions_table.dart';
import 'tables/budgets_table.dart';
import 'tables/category_budgets_table.dart';
import 'tables/settings_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CategoriesTable,
    TransactionsTable,
    BudgetsTable,
    CategoryBudgetsTable,
    SettingsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(join(dir.path, 'tmmi.db'));
    return NativeDatabase(file);
  });
}
