# 数据库 (drift ORM / SQLite)

数据库文件: `tmmi.db`, 位于应用文档目录。通过 `build_runner` 生成代码 (`app_database.g.dart`)。

## 表结构

| 表 | 关键列 |
|----|--------|
| `CategoriesTable` | id (PK), name, icon, color, type ("expense"/"income"), sortOrder, createdAt, updatedAt |
| `TransactionsTable` | id (PK), amount, categoryId (FK→Categories), type, date, note?, createdAt, updatedAt |
| `BudgetsTable` | id (PK), amount, period, year, month?, createdAt, updatedAt |
| `CategoryBudgetsTable` | id (PK), budgetId (FK→Budgets), categoryId (FK→Categories), amount |
| `SettingsTable` | key (PK), value |

## DAO

- **TransactionDao** — CRUD + watchByMonth, watchByType, search, watchMonthlySummary, watchDailyTotals, watchCategoryRanking, watchYearlyMonthlyTotals, getByDateRange, getMonthlyTotalByType
- **CategoryDao** — CRUD + watchAll, watchByType, updateSortOrder
- **BudgetDao** — getMonthly, upsertMonthlyBudget, upsertCategoryBudget, getCategoryBudgets, setCategoryBudget
- **SettingsDao** — get, set (upsert 键值对)

## 命名约定

- drift DataClass: `<TableName>TableData` (如 `TransactionsTableData`, `CategoriesTableData`)
- DAO 方法: `get*` (一次性), `watch*` (流), `insert`/`update`/`delete`
- 插入/更新使用 `*TableCompanion` 对象, 字段用 `Value(...)` 包装

## 迁移与初始化

- 迁移逻辑在 `lib/data/database/app_database.dart` 中维护
- 首次启动写入预设分类: 12 个支出分类 + 6 个收入分类 (`lib/core/constants/preset_categories.dart`)

## 相关文件

| 文件 | 用途 |
|------|------|
| `lib/data/database/app_database.dart` | `AppDatabase` + 迁移 + 初始数据 |
| `lib/data/database/tables/` | 表定义 |
| `lib/data/database/daos/` | DAO 实现 |
| `lib/providers/database_provider.dart` | DAO 的 Riverpod 注入 |

修改表结构后必须运行:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
