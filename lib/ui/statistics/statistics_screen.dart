import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/ui/shared/icon_helpers.dart';

/// 周期类型状态：'week' 表示按周展示，'month' 表示按月展示
final periodTypeProvider = StateProvider<String>((ref) => 'week');

/// 星期标签：周一到周日
const List<String> _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

/// 统计页面 - 展示月度支出统计、消费趋势柱状图和分类明细
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听当前选中的月份
    final month = ref.watch(currentMonthProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 根据主题亮度适配状态栏样式
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏：标题 + 回到今天按钮 + 周期按钮
            const _Header(),
            // 可滚动的统计内容区域
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),
                  // 月度总支出概览卡片
                  _OverviewCard(month: month),
                  const SizedBox(height: 16),
                  // 消费趋势柱状图卡片
                  _ChartCard(month: month),
                  const SizedBox(height: 16),
                  // 支出分类明细卡片
                  _CategoryCardSection(month: month),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部导航栏：显示"支出统计"标题、回到今天按钮和周期选择按钮
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当前选中的月份
    final month = ref.watch(currentMonthProvider);
    // 实际当前月份
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, 1);
    // 判断是否已处于当前月份
    final isCurrentMonth = month.year == today.year && month.month == today.month;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 标题文字
            Text(
              '支出统计',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textOnSurface(context),
              ),
            ),
            Row(
              children: [
                // 回到今天按钮（仅在非当前月时显示）
                if (!isCurrentMonth)
                  GestureDetector(
                    onTap: () {
                      // 将选中的月份重置为当前月
                      ref.read(currentMonthProvider.notifier).state = today;
                    },
                    child: Container(
                      width: 64,
                      height: 36,
                      decoration: AppTheme.glassDecoration(
                        radius: 18,
                        context: context,
                      ),
                      child: Center(
                        child: Text(
                          '回到今天',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textOnSurface(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!isCurrentMonth) const SizedBox(width: 8),
                // 周期选择毛玻璃按钮
                const _PeriodButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 周期选择按钮：在"周"和"月"之间切换图表显示粒度
class _PeriodButton extends ConsumerWidget {
  const _PeriodButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当前周期模式
    final periodType = ref.watch(periodTypeProvider);
    // 按钮文字显示当前模式
    final label = periodType == 'week' ? '周' : '月';
    return GestureDetector(
      onTap: () {
        // 周/月模式切换
        final next = periodType == 'week' ? 'month' : 'week';
        ref.read(periodTypeProvider.notifier).state = next;
      },
      child: Container(
        width: 80,
        height: 36,
        decoration: AppTheme.glassDecoration(
          radius: 18,
          context: context,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textOnSurface(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// 本月总支出概览卡片（radius 20，毛玻璃 + 阴影）
class _OverviewCard extends ConsumerWidget {
  final DateTime month;
  const _OverviewCard({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当前月份汇总数据
    final statsAsync = ref.watch(monthlyStatsProvider(month));
    // 上个月汇总数据（用于环比计算）
    final prevMonth = DateTime(month.year, month.month - 1, 1);
    final prevStatsAsync = ref.watch(monthlyStatsProvider(prevMonth));
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
          // "X月总支出" 标签（60% 透明度）
          Text(
            '${month.year}年${month.month}月总支出',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          // 大号金额（从数据库实时读取）
          statsAsync.when(
            data: (stats) => Text(
              '¥ ${NumberFormat('#,###').format(stats.totalExpense.round())}',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppTheme.textOnSurface(context),
              ),
            ),
            loading: () => const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Text(
              '¥ 0',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppTheme.textOnSurface(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 环比变化文字
          _buildCompareText(context, statsAsync, prevStatsAsync),
        ],
      ),
    );
  }

  /// 构建月度环比变化文字
  Widget _buildCompareText(
    BuildContext context,
    AsyncValue currentAsync,
    AsyncValue prevAsync,
  ) {
    // 两个数据源均加载完成后才计算环比
    final current = currentAsync.asData?.value;
    final prev = prevAsync.asData?.value;
    if (current == null || prev == null) {
      return const SizedBox.shrink();
    }
    final currentExpense = current.totalExpense;
    final prevExpense = prev.totalExpense;
    // 上月支出为 0 时无法计算环比
    if (prevExpense == 0) {
      return const SizedBox.shrink();
    }
    // 计算变化百分比
    final change = ((currentExpense - prevExpense) / prevExpense) * 100;
    final isUp = change >= 0;
    final color = isUp ? const Color(0xFFF87171) : const Color(0xFF4ADE80);
    final arrow = isUp ? '↑' : '↓';
    return Text(
      '较上月 $arrow ${change.abs().toStringAsFixed(1)}%',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

/// 消费趋势图表卡片（radius 18），支持周/月两种粒度
class _ChartCard extends ConsumerWidget {
  final DateTime month;
  const _ChartCard({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当前周期模式
    final period = ref.watch(periodTypeProvider);
    // 指定月份的每日支出数据流
    final dailyAsync = ref.watch(dailyTotalsProvider(month));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecorationFull(
        context: context,
        radius: 18,
        fill: AppTheme.glassFillStrong(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片标题，根据周期显示不同文字
          Text(
            period == 'week' ? '本周消费趋势' : '本月消费趋势',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const SizedBox(height: 12),
          dailyAsync.when(
            data: (dailyTotals) {
              // 构建 day→total 映射
              final totalMap = {for (var d in dailyTotals) d.day: d.total};
              // 根据周期模式生成柱状图数据和标签
              final chartData = _buildChartData(totalMap, period, month);
              return Column(
                children: [
                  // 柱状图
                  _BarChart(values: chartData.values),
                  const SizedBox(height: 6),
                  // 底部日期标签行
                  _DateLabels(labels: chartData.labels),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 130,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => const SizedBox(
              height: 130,
              child: Center(child: Text('暂无数据')),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据周/月模式构建图表数据，返回柱状图数值列表和对应的标签列表
  _ChartData _buildChartData(
    Map<int, double> totalMap, String period, DateTime month,
  ) {
    if (period == 'week') {
      // 周模式：获取本周一到周日的 7 天数据
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final values = <double>[];
      final labels = <String>[];
      for (var i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        // 仅当月范围内的天数显示有效数据，其余标记为 -1（不可见）
        if (day.month == month.month && day.year == month.year) {
          values.add(totalMap[day.day] ?? 0);
        } else {
          values.add(-1);
        }
        labels.add(_weekdayLabels[i]);
      }
      return _ChartData(values: values, labels: labels);
    } else {
      // 月模式：显示当月全部天数
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      final values = List.generate(lastDay, (i) {
        final day = i + 1;
        return totalMap[day] ?? 0;
      });
      final labels = List.generate(lastDay, (i) => '${i + 1}日');
      return _ChartData(values: values, labels: labels);
    }
  }
}

/// 图表数据容器
class _ChartData {
  final List<double> values;
  final List<String> labels;
  const _ChartData({required this.values, required this.labels});
}

/// 柱状图区域，支持动态数据条数（7 条或当月全部天数），柱高按最大值等比缩放
class _BarChart extends StatelessWidget {
  final List<double> values;
  const _BarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    // 提取有效数据（>= 0）用于计算最大值
    final validValues = values.where((v) => v >= 0).toList();
    if (validValues.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('暂无数据')),
      );
    }
    final maxValue = validValues.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final isValid = v >= 0;
          // 有效数据按比例映射高度（最低 5px 保证可见），无效数据高度为 0
          final height = isValid && maxValue > 0 ? (v / maxValue) * 95 + 5 : 0.0;
          // 透明度随值大小在 0.25~0.5 之间变化
          final opacity = isValid && maxValue > 0
              ? 0.25 + (v / maxValue) * 0.25
              : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: isValid
                      ? AppTheme.textOnSurface(context).withValues(alpha: opacity)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 底部日期标签行
class _DateLabels extends StatelessWidget {
  final List<String> labels;
  const _DateLabels({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textOnSurface(context).withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 支出分类卡片（radius 18），从数据库获取实时分类排行数据
class _CategoryCardSection extends ConsumerWidget {
  final DateTime month;
  const _CategoryCardSection({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当前月支出分类排行流
    final rankingsAsync = ref.watch(
      categoryRankingProvider((month: month, type: 'expense')),
    );
    // 全部分类信息流（含名称、图标、颜色）
    final categoriesAsync = ref.watch(allCategoriesProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 10, 16),
      decoration: AppTheme.glassDecorationFull(
        context: context,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片标题
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '支出分类',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textOnSurface(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 异步加载分类排行数据
          rankingsAsync.when(
            data: (rankings) => categoriesAsync.when(
              data: (categories) {
                // 建立分类 id 到 CategoriesTableData 的映射
                final catMap = {for (var c in categories) c.id: c};
                if (rankings.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('暂无数据')),
                  );
                }
                // 计算总支出去求和所有排行数据
                final totalExpense = rankings.fold<double>(0, (sum, r) => sum + r.total);
                final maxTotal = rankings.first.total;
                return Column(
                  children: rankings.map((r) {
                    final cat = catMap[r.categoryId];
                    final name = cat?.name ?? '未知';
                    final color = cat != null ? parseHexColor(cat.color) : Colors.grey;
                    final percentage = totalExpense > 0 ? (r.total / totalExpense) * 100 : 0.0;
                    final progress = maxTotal > 0 ? r.total / maxTotal : 0.0;
                    return _CategoryRow(
                      name: name,
                      amount: r.total,
                      percentage: percentage,
                      color: color,
                      progress: progress,
                    );
                  }).toList(),
                );
              },
              loading: () => _buildCategoryLoading(),
              error: (_, _) => const Center(child: Text('加载分类信息失败')),
            ),
            loading: () => _buildCategoryLoading(),
            error: (_, _) => const Center(child: Text('加载排行数据失败')),
          ),
        ],
      ),
    );
  }

  /// 分类数据加载中的占位状态
  Widget _buildCategoryLoading() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

/// 单条分类行：彩色圆点 + 名称 + 金额 + 百分比 + 进度条
class _CategoryRow extends StatelessWidget {
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  final double progress;

  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          // 上排：圆点 + 名称 + 金额 + 百分比
          Row(
            children: [
              // 分类彩色圆点（8×8 圆形）
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // 分类名称
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textOnSurface(context),
                  ),
                ),
              ),
              // 金额
              Text(
                '¥${NumberFormat('#,###').format(amount.round())}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textOnSurface(context),
                ),
              ),
              const SizedBox(width: 4),
              // 百分比
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textOnSurface(context).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 进度条（4px 高，彩色填充）
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.textOnSurface(
                context,
              ).withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
