import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/transaction_dao.dart';
import '../data/database/daos/category_dao.dart';
import '../data/database/daos/budget_dao.dart';
import '../data/database/daos/settings_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao(ref.watch(databaseProvider));
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return CategoryDao(ref.watch(databaseProvider));
});

final budgetDaoProvider = Provider<BudgetDao>((ref) {
  return BudgetDao(ref.watch(databaseProvider));
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(databaseProvider));
});