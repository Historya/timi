// 预算页面 - 从数据库加载真实预算数据
//
// 包含：预算总览卡片（月度预算金额、进度条、已用/剩余统计）
// 和分类预算卡片（各分类预算与实际花费对比）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/ui/shared/icon_helpers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  /// 格式化金额，带千分位分隔
  String _formatCurrency(double amount, {int decimals = 2}) {
    final str = amount.toStringAsFixed(decimals);
    final parts = str.split('.');
    final intPart = parts[0];
    final result = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) result.write(',');
      result.write(intPart[i]);
    }
    if (decimals > 0) {
      result.write('.');
      result.write(parts[1]);
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前选中的月份
    final month = ref.watch(currentMonthProvider);
    // 加载该月份的完整预算数据
    final budgetAsync = ref.watch(
      monthlyBudgetProvider((year: month.year, month: month.month)),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              Expanded(
                child: budgetAsync.when(
                  data: (budgetData) {
                    if (budgetData == null) {
                      // 未设置预算时显示空状态
                      return _buildEmptyState(context);
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBudgetOverview(context, budgetData),
                          const SizedBox(height: 24),
                          _buildSectionTitle(context),
                          const SizedBox(height: 12),
                          _buildCategoryBudgetCard(context, budgetData),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Text(
                        '加载失败: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 头部：返回箭头 24px + "预算设置" 20px bold centered + 24px spacer
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              PhosphorIconsLight.arrowLeft,
              size: 24,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const Spacer(),
          Text(
            '预算设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  /// "分类预算" 标题 13px
  Widget _buildSectionTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        '分类预算',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
        ),
      ),
    );
  }

  /// 空状态：尚未设置月度预算
  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        children: [
          const SizedBox(height: 80),
          Icon(
            PhosphorIconsLight.wallet,
            size: 64,
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '尚未设置月度预算',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 预算总览卡片（radius 20, glass, padding 20, gap 12, shadow）
  Widget _buildBudgetOverview(
    BuildContext context,
    MonthlyBudgetData data,
  ) {
    // 计算剩余金额
    final remaining = data.totalBudget - data.totalSpent;
    // 计算进度占比（防止除零）
    final ratio = data.totalBudget > 0
        ? (data.totalSpent / data.totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecorationFull(
        context: context,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '月度预算',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '¥ ${_formatCurrency(data.totalBudget)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textOnSurface(context),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                PhosphorIconsLight.pencilSimple,
                size: 20,
                color:
                    AppTheme.textOnSurface(context).withValues(alpha: 0.54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 进度条：根据实际花费占比渲染宽高比
          LayoutBuilder(
            builder: (context, constraints) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Flexible(
                        flex: (ratio * 1000).ceil(),
                        child: Container(color: AppTheme.accentGreen),
                      ),
                      if (ratio < 1)
                        Flexible(
                          flex: ((1 - ratio) * 1000).ceil(),
                          child:
                              Container(color: AppTheme.glassWhite1a),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '已用 ¥${_formatCurrency(data.totalSpent, decimals: 0)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textOnSurface(context),
                ),
              ),
              const Spacer(),
              Text(
                '剩余 ¥${_formatCurrency(remaining, decimals: 0)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textOnSurface(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 分类预算卡片（radius 16, glass, border）
  Widget _buildCategoryBudgetCard(
    BuildContext context,
    MonthlyBudgetData data,
  ) {
    final list = data.categoryBudgets;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: AppTheme.glassDecoration(
        radius: 16,
        fill: AppTheme.glassFillStrong(context),
        context: context,
      ),
      child: Column(
        children: List.generate(list.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const Divider(height: 1, color: AppTheme.glassStroke33);
          }
          final cat = list[index ~/ 2];
          return _buildCategoryRow(context, cat);
        }),
      ),
    );
  }

  /// 单行分类 (h 48, gap 12): icon 20px + 名称 15px + mini bar + 金额 12px
  Widget _buildCategoryRow(
    BuildContext context,
    CategoryBudgetWithSpending cat,
  ) {
    // 计算该分类的预算使用比例
    final ratio = cat.budgetAmount > 0
        ? (cat.actualSpent / cat.budgetAmount).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Icon(
            resolveCategoryIcon(cat.category.icon),
            size: 20,
            color: parseHexColor(cat.category.color),
          ),
          const SizedBox(width: 12),
          Text(
            cat.category.name,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const SizedBox(width: 12),
          // 分类进度条：按实际花费占比填充
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 80,
              height: 4,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 4,
                    color: AppTheme.glassWhite1a,
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      height: 4,
                      color: parseHexColor(cat.category.color),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            '¥${cat.budgetAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textOnSurface(context),
            ),
          ),
        ],
      ),
    );
  }
}
