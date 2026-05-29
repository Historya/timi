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

  /// 设置月度预算，已存在则更新，不存在则插入
  Future<void> upsertMonthlyBudget({
    required double amount,
    required int year,
    required int month,
  }) async {
    final existing = await getMonthly(year, month);
    final now = DateTime.now();

    if (existing != null) {
      // 已有记录 → 更新金额和时间戳
      await _db.update(_db.budgetsTable).replace(
        existing.copyWith(
          amount: amount,
          updatedAt: now,
        ),
      );
    } else {
      // 无记录 → 插入新行
      await _db.into(_db.budgetsTable).insert(
        BudgetsTableCompanion(
          amount: Value(amount),
          period: const Value('monthly'),
          year: Value(year),
          month: Value(month),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// 设置分类预算，已存在则更新，不存在则插入
  Future<void> upsertCategoryBudget({
    required int budgetId,
    required int categoryId,
    required double amount,
  }) async {
    // 检查是否已有该分类的预算记录
    final query = _db.select(_db.categoryBudgetsTable)
      ..where(
        (cb) =>
            cb.budgetId.equals(budgetId) &
            cb.categoryId.equals(categoryId),
      );
    final existing = await query.getSingleOrNull();

    if (existing != null) {
      // 已有记录 → 更新金额
      await _db.update(_db.categoryBudgetsTable).replace(
        existing.copyWith(amount: amount),
      );
    } else {
      // 无记录 → 插入新行
      await _db.into(_db.categoryBudgetsTable).insert(
        CategoryBudgetsTableCompanion(
          budgetId: Value(budgetId),
          categoryId: Value(categoryId),
          amount: Value(amount),
        ),
      );
    }
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