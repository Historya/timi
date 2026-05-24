import 'package:drift/drift.dart';
import 'budgets_table.dart';
import 'categories_table.dart';

class CategoryBudgetsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId => integer().references(BudgetsTable, #id)();
  IntColumn get categoryId => integer().references(CategoriesTable, #id)();
  RealColumn get amount => real()();
}