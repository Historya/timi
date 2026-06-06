import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/constants/transaction_type.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/ui/shared/icon_helpers.dart';
import 'package:timi/l10n/app_localizations.dart';

/// 返回日期的相对标签："今天" / "昨天" / "M月d日"
String _formatDateLabel(DateTime date, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(date.year, date.month, date.day);
  if (dateDay == today) return l10n.today;
  if (dateDay == today.subtract(const Duration(days: 1))) return l10n.yesterday;
  return DateFormat('M/dd').format(date);
}

/// 格式化交易时间为相对描述："今天 12:30" / "昨天 09:15" / "MM/dd HH:mm"
String _formatTime(DateTime date, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(date.year, date.month, date.day);
  final timeFmt = DateFormat('HH:mm');
  if (dateDay == today) return '${l10n.today} ${timeFmt.format(date)}';
  if (dateDay == today.subtract(const Duration(days: 1))) {
    return '${l10n.yesterday} ${timeFmt.format(date)}';
  }
  return DateFormat('MM/dd HH:mm').format(date);
}

/// 按日期（年月日）分组交易记录
Map<DateTime, List<TransactionsTableData>> _groupByDate(
  List<TransactionsTableData> items,
) {
  final map = <DateTime, List<TransactionsTableData>>{};
  for (final item in items) {
    final day = DateTime(item.date.year, item.date.month, item.date.day);
    map.putIfAbsent(day, () => []).add(item);
  }
  return map;
}

/// 账单明细页面（从首页/账单 tab 路由 push 而来）
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当前选中的月份
    final month = ref.watch(currentMonthProvider);
    // 该月的交易记录流
    final transactionsAsync = ref.watch(transactionsByMonthProvider(month));

    // 下拉刷新方法
    Future<void> refresh() {
      ref.invalidate(transactionsByMonthProvider(month));
      return Future<void>.value();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle(context),
      child: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏 + 搜索按钮
            const _Header(),
            // 月份选择器
            _MonthSelector(month: month),
            const SizedBox(height: 8),
            // 内容区域（汇总卡片 + 交易列表）
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  // 获取全部分类映射
                  final categories =
                      ref.watch(allCategoriesProvider).valueOrNull ?? [];
                  final catMap = {for (final c in categories) c.id: c};
                  return _Content(
                    transactions: transactions,
                    categoryMap: catMap,
                    onRefresh: refresh,
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.textOnSurface(
                      context,
                    ).withValues(alpha: 0.54),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '$err',
                      style: TextStyle(
                        color: AppTheme.textOnSurface(
                          context,
                        ).withValues(alpha: 0.54),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部标题栏："账单明细" + 搜索按钮（40×40 圆形毛玻璃）
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // "账单明细" 标题，22px 粗体
            Text(
              AppLocalizations.of(context).billDetail,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textOnSurface(context),
              ),
            ),
            // 搜索按钮（40×40 圆形毛玻璃）
            Tooltip(
              message: AppLocalizations.of(context).search,
              child: Container(
                width: 40,
                height: 40,
                decoration: AppTheme.glassDecoration(
                  radius: 20,
                  fill: AppTheme.glassFillAccent(context),
                  context: context,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    PhosphorIconsLight.magnifyingGlass,
                    color: AppTheme.textOnSurface(context),
                    size: 20,
                  ),
                  onPressed: () => context.push('/search'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 月份选择器：< 2026年5月 >，按钮 36×36 圆形毛玻璃
class _MonthSelector extends ConsumerWidget {
  final DateTime month;
  const _MonthSelector({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = DateFormat.yMMM(l10n.localeName);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上个月按钮（36×36 圆形）
          Tooltip(
            message: l10n.previousMonth,
            child: GestureDetector(
              onTap: () {
                ref.read(currentMonthProvider.notifier).state = DateTime(
                  month.year,
                  month.month - 1,
                  1,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: AppTheme.glassDecoration(
                  radius: 18,
                  fill: AppTheme.glassFillAccent(context),
                  context: context,
                ),
                child: Icon(
                  PhosphorIconsLight.caretLeft,
                  color: AppTheme.textOnSurface(context),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 当前月份文本，16px 粗体
          Text(
            fmt.format(month),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const SizedBox(width: 16),
          // 下个月按钮（36×36 圆形）
          Tooltip(
            message: l10n.nextMonth,
            child: GestureDetector(
              onTap: () {
                ref.read(currentMonthProvider.notifier).state = DateTime(
                  month.year,
                  month.month + 1,
                  1,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: AppTheme.glassDecoration(
                  radius: 18,
                  fill: AppTheme.glassFillAccent(context),
                  context: context,
                ),
                child: Icon(
                  PhosphorIconsLight.caretRight,
                  color: AppTheme.textOnSurface(context),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 账单列表主体：月汇总卡片 + 按日期分组的交易记录
class _Content extends StatelessWidget {
  final List<TransactionsTableData> transactions;
  final Map<int, CategoriesTableData> categoryMap;
  final Future<void> Function() onRefresh;

  const _Content({
    required this.transactions,
    required this.categoryMap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // 计算本月收入总额
    // 计算本月收入总额
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income.value)
        .fold<double>(0, (sum, t) => sum + t.amount);
    // 计算本月支出总额
    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense.value)
        .fold<double>(0, (sum, t) => sum + t.amount);

    // 按日期分组整理
    final grouped = _groupByDate(transactions);
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (transactions.isEmpty) {
      // 空状态占位
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.textOnSurface(context),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsLight.receipt,
                      size: 64,
                      color: AppTheme.textOnSurface(
                        context,
                      ).withValues(alpha: 0.24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).noTransactions,
                      style: TextStyle(
                        color: AppTheme.textOnSurface(
                          context,
                        ).withValues(alpha: 0.38),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.textOnSurface(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 月汇总毛玻璃卡片
          _MonthlySummaryCard(income: totalIncome, expense: totalExpense),
          const SizedBox(height: 16),
          // 按日期分组的交易列表
          ...sortedDates.asMap().entries.map((entry) {
            final idx = entry.key;
            final date = entry.value;
            return _DateGroup(
              date: date,
              items: grouped[date]!,
              categoryMap: categoryMap,
              startIndex: idx * 10,
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

/// 月汇总毛玻璃卡片：本月收入 | 垂直分割线 | 本月支出
class _MonthlySummaryCard extends StatelessWidget {
  final double income;
  final double expense;

  const _MonthlySummaryCard({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecorationFull(
        context: context,
        radius: 16,
      ),
      child: Row(
        children: [
          // 左侧：本月收入
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).thisMonthIncome,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textOnSurface(
                      context,
                    ).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '¥${NumberFormat('#,###').format(income)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ],
            ),
          ),
          // 垂直分隔线
          Container(
            width: 1,
            height: 48,
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.1),
          ),
          // 右侧：本月支出
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).thisMonthExpense,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textOnSurface(
                      context,
                    ).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '¥${NumberFormat('#,###').format(expense)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF87171),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 按日期分组："今天" / "昨天" / "M月d日" + 该日交易列表
class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<TransactionsTableData> items;
  final Map<int, CategoriesTableData> categoryMap;
  final int startIndex;

  const _DateGroup({
    required this.date,
    required this.items,
    required this.categoryMap,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标签：14px 70% 透明度
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              _formatDateLabel(date, AppLocalizations.of(context)),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textOnSurfaceSecondary(context),
              ),
            ),
          ),
          // 该日期下的交易记录列表
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final t = entry.value;
            return _BillItem(
              transaction: t,
              category: categoryMap[t.categoryId],
              index: startIndex + idx,
            );
          }),
        ],
      ),
    );
  }
}

/// 单条交易记录毛玻璃卡片项
class _BillItem extends StatelessWidget {
  final TransactionsTableData transaction;
  final CategoriesTableData? category;
  final int index;

  const _BillItem({required this.transaction, this.category, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense.value;
    // 支出红色 / 收入绿色
    final amountColor = isExpense
        ? const Color(0xFFF87171)
        : const Color(0xFF4ADE80);
    final sign = isExpense ? '-' : '+';
    final name = category?.name ?? AppLocalizations.of(context).uncategorized;
    // 相对时间描述
    final timeStr = _formatTime(transaction.date, AppLocalizations.of(context));

    // 分类图标及颜色
    final icon = category != null
        ? resolveCategoryIcon(category!.icon)
        : PhosphorIconsLight.placeholder;
    final iconBg = category != null
        ? parseHexColor(category!.color).withValues(alpha: 0.2)
        : AppTheme.textOnSurface(context).withValues(alpha: 0.12);
    final iconColor = category != null
        ? parseHexColor(category!.color)
        : AppTheme.textOnSurface(context).withValues(alpha: 0.38);

    return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassDecoration(
              radius: 14,
              fill: AppTheme.glassFillStrong(context),
              stroke: AppTheme.glassStroke(context),
            ),
            child: InkWell(
              onTap: () => context.push('/detail/${transaction.id}'),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  // 分类图标（24×24 圆角方形）
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 14),
                  ),
                  // 间距 12px（设计稿 gap 12）
                  const SizedBox(width: 12),
                  // 名称 + 时间/类型
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textOnSurface(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textOnSurface(
                              context,
                            ).withValues(alpha: 0.54),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 金额：-¥xx.xx 红色 / +¥xx.xx 绿色
                  Text(
                    '$sign¥${NumberFormat('#,###.00').format(transaction.amount)}',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 30).ms)
        .slideX(begin: 0.08, end: 0);
  }
}
