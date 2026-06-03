import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:timi/core/constants/settings_keys.dart';
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

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (OpeningDetails details) async {
      if (details.wasCreated) {
        // 数据库首次创建，插入默认分类、默认设置等
        await into(settingsTable).insert(
          SettingsTableCompanion(
            key: Value(SettingsKeys.tencentAppId),
            value: Value("1303935613"),
          ),
        );
        await into(settingsTable).insert(
          SettingsTableCompanion(
            key: Value(SettingsKeys.tencentSecretId),
            value: Value(""),
          ),
        );
        await into(settingsTable).insert(
          SettingsTableCompanion(
            key: Value(SettingsKeys.tencentSecretKey),
            value: Value(""),
          ),
        );
        await into(settingsTable).insert(
          SettingsTableCompanion(
            key: Value(SettingsKeys.semanticParserEngine),
            value: Value(SemanticParserEngineType.dashscope),
          ),
        );
        await into(settingsTable).insert(
          SettingsTableCompanion(
            key: Value(SettingsKeys.dashscopeLlmApiKey),
            value: Value(""),
          ),
        );
        await into(settingsTable).insert(
          SettingsTableCompanion(
            key: Value(SettingsKeys.asrEngine),
            value: Value(AsrEngineType.tencent),
          ),
        );
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(join(dir.path, 'tmmi.db'));
    return NativeDatabase(file);
  });
}
