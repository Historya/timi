import 'package:drift/drift.dart';
import '../app_database.dart';

class BudgetDao {
  final AppDatabase _db;
  BudgetDao(this._db);

  Future<BudgetsTableData?> getMonthly(int year, int month) {
    return (_db.select(_db.budgetsTable)
      ..where((b) => b.year.equals(year) & b.month.equals(month))
    ).getSingleOrNull();
  }

  Future<int> setBudget(BudgetsTableCompanion entry) {
    return _db.into(_db.budgetsTable).insert(entry);
  }

  Future<List<CategoryBudgetsTableData>> getCategoryBudgets(int budgetId) {
    return (_db.select(_db.categoryBudgetsTable)
      ..where((cb) => cb.budgetId.equals(budgetId))
    ).get();
  }

  Future<int> setCategoryBudget(CategoryBudgetsTableCompanion entry) {
    return _db.into(_db.categoryBudgetsTable).insert(entry);
  }
}