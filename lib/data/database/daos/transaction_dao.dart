import 'package:drift/drift.dart';
import '../app_database.dart';

class TransactionDao {
  final AppDatabase _db;
  TransactionDao(this._db);

  Future<List<TransactionsTableData>> getAll() => _db.select(_db.transactionsTable).get();

  Stream<List<TransactionsTableData>> watchAll() => _db.select(_db.transactionsTable).watch();

  Future<TransactionsTableData> getById(int id) {
    return (_db.select(_db.transactionsTable)..where((t) => t.id.equals(id))).getSingle();
  }

  /// 统计引用指定分类的交易笔数
  Future<int> countByCategoryId(int categoryId) {
    return (_db.select(_db.transactionsTable)
      ..where((t) => t.categoryId.equals(categoryId))
    ).get().then((rows) => rows.length);
  }

  Future<int> insert(TransactionsTableCompanion entry) {
    return _db.into(_db.transactionsTable).insert(entry);
  }

  Future<bool> update(TransactionsTableCompanion entry) {
    return _db.update(_db.transactionsTable).replace(entry);
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.transactionsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<TransactionsTableData>> watchByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (_db.select(_db.transactionsTable)
      ..where((t) => t.date.isBetween(Variable(start), Variable(end)))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
    ).watch();
  }

  Stream<List<TransactionsTableData>> watchByType(String type) {
    return (_db.select(_db.transactionsTable)
      ..where((t) => t.type.equals(type))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
    ).watch();
  }

  Stream<List<TransactionsTableData>> search(String keyword, {String? type, int? categoryId}) {
    var query = _db.select(_db.transactionsTable)
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);
    if (type != null) query.where((t) => t.type.equals(type));
    if (categoryId != null) query.where((t) => t.categoryId.equals(categoryId));
    if (keyword.isNotEmpty) {
      query.where((t) => t.note.like('%$keyword%'));
    }
    return query.watch();
  }

  /// 按月统计汇总：总收入、总支出、总笔数（响应式）
  ///
  /// 基于标准 [select] 查询的 [watch]，确保 drift 能正确追踪 transactions_table 变更，
  /// 避免 customSelect 可能存在的表依赖追踪不完整问题。
  Stream<MonthlySummary> watchMonthlySummary(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (_db.select(_db.transactionsTable)
      ..where((t) => t.date.isBetween(Variable(start), Variable(end)))
    ).watch().map((transactions) {
      // 在 Dart 侧计算汇总，而非 SQL 聚合
      double totalExpense = 0;
      double totalIncome = 0;
      for (final t in transactions) {
        if (t.type == 'expense') {
          totalExpense += t.amount;
        } else {
          totalIncome += t.amount;
        }
      }
      return MonthlySummary(
        totalExpense: totalExpense,
        totalIncome: totalIncome,
        totalCount: transactions.length,
      );
    });
  }

  /// 按月获取每日支出汇总（响应式）
  Stream<List<DailyTotal>> watchDailyTotals(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _db.customSelect(
      '''
      SELECT CAST(strftime('%d', date / 1000, 'unixepoch') AS INTEGER) as day,
             COALESCE(SUM(amount), 0) as total
      FROM transactions_table
      WHERE date >= ? AND date < ? AND type = 'expense'
      GROUP BY day
      ORDER BY day
      ''',
      variables: [Variable(start), Variable(end)],
    ).watch().map((rows) {
      return rows.map((row) => DailyTotal(
        day: row.read<int>('day'),
        total: row.read<double>('total'),
      )).toList();
    });
  }

  /// 按月按类型获取分类排行（响应式）
  Stream<List<CategoryRanking>> watchCategoryRanking(int year, int month, String type) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _db.customSelect(
      '''
      SELECT category_id,
             COALESCE(SUM(amount), 0) as total
      FROM transactions_table
      WHERE date >= ? AND date < ? AND type = ?
      GROUP BY category_id
      ORDER BY total DESC
      ''',
      variables: [Variable(start), Variable(end), Variable(type)],
    ).watch().map((rows) {
      return rows.map((row) => CategoryRanking(
        categoryId: row.read<int>('category_id'),
        total: row.read<double>('total'),
      )).toList();
    });
  }

  /// 获取指定年份 1-12 月每月的支出汇总（响应式）
  Stream<List<MonthlyTotal>> watchYearlyMonthlyTotals(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    return _db.customSelect(
      '''
      SELECT CAST(strftime('%m', date / 1000, 'unixepoch') AS INTEGER) as month,
             COALESCE(SUM(amount), 0) as total
      FROM transactions_table
      WHERE date >= ? AND date < ? AND type = 'expense'
      GROUP BY month
      ORDER BY month
      ''',
      variables: [Variable(start), Variable(end)],
    ).watch().map((rows) {
      // 建立当月实际有数据月份的映射
      final monthMap = {
        for (var row in rows) row.read<int>('month'): row.read<double>('total'),
      };
      // 填充全部12个月，无数据的月份补0
      return List.generate(12, (i) => MonthlyTotal(
        month: i + 1,
        total: monthMap[i + 1] ?? 0,
      ));
    });
  }

  /// 按月按类型获取总金额（非响应式）
  Future<double> getMonthlyTotalByType(int year, int month, String type) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final result = await _db.customSelect(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions_table
      WHERE date >= ? AND date < ? AND type = ?
      ''',
      variables: [Variable(start), Variable(end), Variable(type)],
    ).getSingle();
    return result.read<double>('total');
  }
}

/// 月度汇总数据
class MonthlySummary {
  final double totalExpense;
  final double totalIncome;
  final int totalCount;
  MonthlySummary({
    required this.totalExpense,
    required this.totalIncome,
    required this.totalCount,
  });
}

/// 每日支出汇总数据
class DailyTotal {
  final int day;
  final double total;
  DailyTotal({required this.day, required this.total});
}

/// 分类排行数据
class CategoryRanking {
  final int categoryId;
  final double total;
  CategoryRanking({required this.categoryId, required this.total});
}

/// 年度每月支出汇总数据
class MonthlyTotal {
  final int month;
  final double total;
  MonthlyTotal({required this.month, required this.total});
}