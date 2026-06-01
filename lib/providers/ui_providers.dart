import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/data/database/daos/transaction_dao.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/services/asr_service.dart';
import 'package:timi/services/dashscope_asr_service.dart';
import 'package:timi/services/tencent_asr_service.dart';
import 'package:timi/services/semantic_parser_service.dart';
import 'package:timi/services/dashscope_semantic_parser.dart';

/// 月度预算完整数据（总预算 + 各分类预算 + 实际花费）
class MonthlyBudgetData {
  final double totalBudget;
  final double totalSpent;
  final List<CategoryBudgetWithSpending> categoryBudgets;

  MonthlyBudgetData({
    required this.totalBudget,
    required this.totalSpent,
    required this.categoryBudgets,
  });
}

/// 单个分类预算与花费对比
class CategoryBudgetWithSpending {
  final CategoriesTableData category;
  final double budgetAmount;
  final double actualSpent;

  CategoryBudgetWithSpending({
    required this.category,
    required this.budgetAmount,
    required this.actualSpent,
  });
}

/// 当前选中的月份（每月1日）
final currentMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// 指定月份的交易记录流
final transactionsByMonthProvider = StreamProvider.autoDispose
    .family<List<TransactionsTableData>, DateTime>((ref, month) {
      return ref
          .watch(transactionDaoProvider)
          .watchByMonth(month.year, month.month);
    });

/// 按类型查询分类流（expense/income）
final categoriesByTypeProvider = StreamProvider.autoDispose
    .family<List<CategoriesTableData>, String>((ref, type) {
      return ref.watch(categoryDaoProvider).watchByType(type);
    });

/// 全部分类流
final allCategoriesProvider =
    StreamProvider.autoDispose<List<CategoriesTableData>>((ref) {
      return ref.watch(categoryDaoProvider).watchAll();
    });

/// 语言切换 Notifier：写 DB + 更新状态一次完成，消除双写
class LocaleNotifier extends Notifier<Locale> {
  bool _disposed = false;

  @override
  Locale build() {
    // 初始化时从数据库读取已保存的语言偏好
    ref.onDispose(() => _disposed = true);
    Future.microtask(() async {
      final dao = ref.read(settingsDaoProvider);
      final lang = await dao.get('language');
      if (lang != null && !_disposed) {
        state = Locale(lang);
      }
    });
    return const Locale('zh');
  }

  /// 切换语言：写入数据库并更新状态
  Future<void> setLanguage(String lang) async {
    final dao = ref.read(settingsDaoProvider);
    await dao.set('language', lang);
    state = Locale(lang);
  }
}

/// 当前语言偏好（默认中文）
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// 主题切换 Notifier：写 DB + 更新状态一次完成
class ThemeModeNotifier extends Notifier<ThemeMode> {
  bool _disposed = false;

  @override
  ThemeMode build() {
    // 初始化时从数据库读取已保存的主题偏好
    ref.onDispose(() => _disposed = true);
    Future.microtask(() async {
      final dao = ref.read(settingsDaoProvider);
      final saved = await dao.get('theme_mode');
      if (saved != null && !_disposed) {
        state = switch (saved) {
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          _ => ThemeMode.system,
        };
      }
    });
    return ThemeMode.system;
  }

  /// 循环切换：跟随系统 → 深色 → 浅色 → 跟随系统
  Future<void> toggle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
    };
    final dao = ref.read(settingsDaoProvider);
    await dao.set('theme_mode', switch (next) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      _ => 'system',
    });
    state = next;
  }
}

/// 当前主题模式（暗色/浅色）
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// 当前选中的标签页索引（0=首页, 1=账单, 2=统计, 3=我的）
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

/// 指定月份的汇总统计数据（总支出、总收入、总笔数）
final monthlyStatsProvider = StreamProvider.autoDispose
    .family<MonthlySummary, DateTime>((ref, month) {
      return ref
          .watch(transactionDaoProvider)
          .watchMonthlySummary(month.year, month.month);
    });

/// 指定月份的每日支出汇总（用于柱状图）
final dailyTotalsProvider = StreamProvider.autoDispose
    .family<List<DailyTotal>, DateTime>((ref, month) {
      return ref
          .watch(transactionDaoProvider)
          .watchDailyTotals(month.year, month.month);
    });

/// 指定年份 1-12 月每月支出汇总（用于年度趋势图）
final yearlyMonthlyTotalsProvider = StreamProvider.autoDispose
    .family<List<MonthlyTotal>, int>((ref, year) {
      return ref.watch(transactionDaoProvider).watchYearlyMonthlyTotals(year);
    });

/// 指定月份指定类型的分类排名（含 categoryId 和 total）
final categoryRankingProvider = StreamProvider.autoDispose
    .family<List<CategoryRanking>, ({DateTime month, String type})>((
      ref,
      param,
    ) {
      return ref
          .watch(transactionDaoProvider)
          .watchCategoryRanking(
            param.month.year,
            param.month.month,
            param.type,
          );
    });

/// 按月获取完整预算数据（总预算 + 各分类预算 + 实际花费）
final monthlyBudgetProvider = FutureProvider.autoDispose
    .family<MonthlyBudgetData?, ({int year, int month})>((ref, param) async {
      final budgetDao = ref.watch(budgetDaoProvider);
      final transactionDao = ref.watch(transactionDaoProvider);
      final categoryDao = ref.watch(categoryDaoProvider);

      // 获取月度预算
      final budget = await budgetDao.getMonthly(param.year, param.month);
      if (budget == null) return null;

      // 获取分类预算
      final categoryBudgets = await budgetDao.getCategoryBudgets(budget.id);

      // 获取全部分类并建立 id -> CategoriesTableData 的映射
      final allCategories = await categoryDao.getAll();
      final categoryMap = {for (var c in allCategories) c.id: c};

      // 获取各分类实际花费（从分类排行流取首次数据）
      final rankings = await transactionDao
          .watchCategoryRanking(param.year, param.month, 'expense')
          .first;
      final rankingMap = {for (var r in rankings) r.categoryId: r.total};

      // 获取当月全量总支出（包含所有分类，而非仅设有预算的分类）
      final totalSpent = await transactionDao.getMonthlyTotalByType(
        param.year,
        param.month,
        'expense',
      );

      final categorySpending = <CategoryBudgetWithSpending>[];
      for (final cb in categoryBudgets) {
        final category = categoryMap[cb.categoryId];
        if (category == null) continue;
        final actualSpent = rankingMap[cb.categoryId] ?? 0;
        categorySpending.add(
          CategoryBudgetWithSpending(
            category: category,
            budgetAmount: cb.amount,
            actualSpent: actualSpent,
          ),
        );
      }

      return MonthlyBudgetData(
        totalBudget: budget.amount,
        totalSpent: totalSpent,
        categoryBudgets: categorySpending,
      );
    });

/// 当前选中的 ASR 引擎实例
///
/// 根据 SettingsTable 中配置的引擎类型（key: "asr_engine"）动态创建对应的 AsrService 实现。
/// - "dashscope" → DashScopeAsrService（默认）
/// - "tencent"   → TencentAsrService（需读取 appId/secretId/secretKey）
final currentAsrEngineProvider = FutureProvider<AsrService>((ref) async {
  final dao = ref.watch(settingsDaoProvider);

  // 从数据库读取引擎类型，默认为 dashscope
  final engine = await dao.get('asr_engine') ?? 'dashscope';

  switch (engine) {
    case 'tencent':
      // 读取腾讯云 ASR 三凭证
      final appId = await dao.get('tencent_app_id') ?? '';
      final secretId = await dao.get('tencent_secret_id') ?? '';
      final secretKey = await dao.get('tencent_secret_key') ?? '';
      return TencentAsrService(
        appId: appId,
        secretId: secretId,
        secretKey: secretKey,
      );
    default:
      // 默认使用阿里云 DashScope
      return DashScopeAsrService();
  }
});

/// 当前选中的 AI 语义解析引擎实例
///
/// 根据 SettingsTable 中配置的引擎类型（key: "semantic_parser_engine"）
/// 动态创建对应的 [SemanticParserService] 实现。
/// - "dashscope" → DashScopeSemanticParser（默认，唯一实现）
///
/// 使用方式：
/// ```dart
/// final parser = await ref.read(currentSemanticParserProvider.future);
/// final hybrid = HybridExpenseParser(service: parser, apiKey: apiKey);
/// final result = await hybrid.parse(text: ...);
/// ```
final currentSemanticParserProvider = FutureProvider<SemanticParserService>((
  ref,
) async {
  final dao = ref.watch(settingsDaoProvider);

  // 从数据库读取引擎类型，默认为 dashscope
  final engine = await dao.get('semantic_parser_engine') ?? 'dashscope';

  switch (engine) {
    default:
      // 默认使用阿里云 DashScope（当前唯一实现）
      return DashScopeSemanticParser();
  }
});
