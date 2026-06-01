import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/ui/shared/icon_helpers.dart';
import 'package:timi/l10n/app_localizations.dart';

/// 格式化交易时间为相对描述
/// 今天 → "今天 12:30"，昨天 → "昨天 09:15"，更早 → "05/14 22:10"
String _formatTime(DateTime date, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(date.year, date.month, date.day);
  final timeFmt = DateFormat('HH:mm');
  if (dateDay == today) {
    return '${l10n.today} ${timeFmt.format(date)}';
  } else if (dateDay == today.subtract(const Duration(days: 1))) {
    return '${l10n.yesterday} ${timeFmt.format(date)}';
  } else {
    return DateFormat('MM/dd HH:mm').format(date);
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前选中的月份
    final currentMonth = ref.watch(currentMonthProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 根据主题亮度适配状态栏样式
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: SafeArea(
        child: Column(
          // 主体内容：页头 + 可滚动列表
          children: [
            const _Header(),
            Expanded(child: _Content(month: currentMonth)),
          ],
        ),
      ),
    );
  }
}

/// 页头："我的账单" + 通知按钮
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
            Text(
              AppLocalizations.of(context).myBills,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textOnSurface(context),
              ),
            ),
            const _BellButton(),
          ],
        ),
      ),
    );
  }
}

/// 铃铛通知按钮
class _BellButton extends StatelessWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context).notification,
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
            PhosphorIconsLight.bell,
            color: AppTheme.textOnSurface(context),
            size: 20,
          ),
          onPressed: () {},
        ),
      ),
    );
  }
}

/// 首页主体可滚动内容
class _Content extends ConsumerWidget {
  final DateTime month;

  const _Content({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取本月交易数据
    final transactionsAsync = ref.watch(transactionsByMonthProvider(month));
    // 获取月度汇总
    final statsAsync = ref.watch(monthlyStatsProvider(month));
    // 获取全部分类（用于解析图标和颜色）
    final categoriesAsync = ref.watch(allCategoriesProvider);

    // 三态处理：分类 → 统计 → 交易 依次展开
    return categoriesAsync.when(
      data: (categories) {
        // 构建分类 id → CategoriesTableData 映射表
        final categoryMap = {for (var c in categories) c.id: c};
        return statsAsync.when(
          data: (stats) {
            return transactionsAsync.when(
              data: (transactions) {
                // 按日期排序取前 5 条
                final sorted = List<TransactionsTableData>.from(transactions)
                  ..sort((a, b) => b.date.compareTo(a.date));
                final recent = sorted.take(5).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 4),
                    _BalanceCard(
                      income: stats.totalIncome,
                      expense: stats.totalExpense,
                    ),
                    const SizedBox(height: 8),
                    const _QuickActions(),
                    const SizedBox(height: 8),
                    const _SectionHeader(),
                    const SizedBox(height: 4),
                    _TransactionCard(
                      transactions: recent,
                      categoryMap: categoryMap,
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('${AppLocalizations.of(context).loadFailed}: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('${AppLocalizations.of(context).loadFailed}: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('${AppLocalizations.of(context).loadFailed}: $err')),
    );
  }
}

/// 资产概览卡片：总资产 + 收入/支出明细
class _BalanceCard extends StatelessWidget {
  final double income;
  final double expense;

  const _BalanceCard({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    final textColor = AppTheme.textOnSurface(context);
    final secondaryColor = textColor.withValues(alpha: 0.7);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        radius: 20,
        fill: AppTheme.glassFillAccent(context),
        context: context,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "总资产 (元)" 标签
          Text(
            AppLocalizations.of(context).totalAssets,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          // 总资产金额
          Text(
            '¥ ${NumberFormat('#,###.00').format(balance)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          // 收入 + 支出明细行（使用 Expanded 防止金额过长溢出）
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${AppLocalizations.of(context).income}  ¥${NumberFormat('#,###').format(income)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 支出
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF87171),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${AppLocalizations.of(context).expense}  ¥${NumberFormat('#,###').format(expense)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 快捷操作栏：4 个毛玻璃圆形快捷按钮
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _QuickAction(
            icon: PhosphorIconsLight.plus,
            iconColor: AppTheme.textOnSurface(context),
            label: AppLocalizations.of(context).expense,
            onTap: () =>
                context.push('/add-transaction', extra: {'type': 'expense'}),
          ),
          const SizedBox(width: 12),
          _QuickAction(
            icon: PhosphorIconsLight.arrowDown,
            iconColor: AppTheme.accentGreen,
            label: AppLocalizations.of(context).income,
            onTap: () =>
                context.push('/add-transaction', extra: {'type': 'income'}),
          ),
          const SizedBox(width: 12),
          _QuickAction(
            icon: PhosphorIconsLight.microphone,
            iconColor: const Color(0xFFFBBF24),
            label: AppLocalizations.of(context).voiceInput,
            onTap: () => context.push('/voice-input'),
          ),
          const SizedBox(width: 12),
          _QuickAction(
            icon: PhosphorIconsLight.dotsThree,
            iconColor: AppTheme.textOnSurface(context),
            label: AppLocalizations.of(context).more,
            onTap: () => context.push('/search'),
          ),
        ],
      ),
    );
  }
}

/// 单个快捷操作按钮
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Tooltip(
            message: label,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 52,
                height: 52,
                decoration: AppTheme.glassDecoration(
                  radius: 26,
                  fill: AppTheme.glassFillAccent(context),
                  context: context,
                  strokeWidth: 1,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// "最近交易" 标题 + "查看全部" 链接
class _SectionHeader extends ConsumerWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context).recentTransactions,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          Tooltip(
            message: AppLocalizations.of(context).viewAll,
            child: GestureDetector(
              onTap: () => ref.read(currentTabIndexProvider.notifier).state = 1,
              child: Text(
                AppLocalizations.of(context).viewAll,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 交易列表卡片：统一玻璃卡片容器，内部包含多条交易行 + 分隔线
class _TransactionCard extends StatelessWidget {
  final List<TransactionsTableData> transactions;
  final Map<int, CategoriesTableData> categoryMap;

  const _TransactionCard({
    required this.transactions,
    required this.categoryMap,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsLight.receipt,
                size: 40,
                color: AppTheme.textOnSurface(context).withValues(alpha: 0.24),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).noTransactions,
                style: TextStyle(
                  color: AppTheme.textOnSurface(
                    context,
                  ).withValues(alpha: 0.38),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: AppTheme.glassDecoration(radius: 16, context: context),
      child: Column(
        children: transactions.asMap().entries.map((entry) {
          final idx = entry.key;
          final t = entry.value;
          final isLast = idx == transactions.length - 1;
          return Column(
            key: ValueKey(t.id),
            children: [
              _TransactionRow(
                transaction: t,
                categoryMap: categoryMap,
                index: idx,
              ),
              // 行间分隔线（最后一条不显示）
              if (!isLast)
                Container(
                  height: 1,
                  color: AppTheme.textOnSurface(
                    context,
                  ).withValues(alpha: 0.08),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// 单条交易记录行
class _TransactionRow extends StatelessWidget {
  final TransactionsTableData transaction;
  final Map<int, CategoriesTableData> categoryMap;
  final int index;

  const _TransactionRow({
    required this.transaction,
    required this.categoryMap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final Color amountColor = isExpense
        ? const Color(0xFFF87171)
        : AppTheme.accentGreen;
    final String sign = isExpense ? '-' : '+';

    // 从分类映射表获取分类数据
    final category = categoryMap[transaction.categoryId];
    final IconData icon = category != null
        ? resolveCategoryIcon(category.icon)
        : PhosphorIconsLight.placeholder;
    final Color iconColor = category != null
        ? parseHexColor(category.color)
        : Colors.grey;
    final Color iconBg = iconColor.withValues(alpha: 0.2);
    // 交易名称 = 分类名，未匹配到则显示"未分类"
    final String name = category?.name ?? AppLocalizations.of(context).uncategorized;
    // 显示格式化时间
    final String timeStr = _formatTime(transaction.date, AppLocalizations.of(context));

    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: InkWell(
            onTap: () => context.push('/detail/${transaction.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // 分类图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                // 名称 + 时间
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textOnSurface(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textOnSurface(
                            context,
                          ).withValues(alpha: 0.54),
                        ),
                      ),
                    ],
                  ),
                ),
                // 金额（防止过长溢出）
                Flexible(
                  child: Text(
                    '$sign¥${NumberFormat('#,###.00').format(transaction.amount)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 30).ms)
        .slideX(begin: 0.08, end: 0);
  }
}
