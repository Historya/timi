// 预算提醒监听器 — 响应式检测月支出是否超预算
//
// 使用方式：包裹在 MaterialApp 外层，自动监听支出变化。
// 当预算提醒开关开启且当月支出超过预算额度时，
// 从顶部滑出磨砂玻璃通知横幅。
//
// 注意：仅在首次超过时弹出，同一次超支不重复提醒。

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timi/core/router/app_router.dart';
import 'package:timi/data/database/daos/transaction_dao.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

/// 预算提醒监听器
///
/// 响应式监听月度支出汇总，在超预算时弹出顶部通知。
/// 复用 [monthlyStatsProvider]（来自 ui_providers）作为支出数据源，
/// 复用 [budgetDaoProvider] 获取当月预算金额。
class BudgetAlertWatcher extends ConsumerStatefulWidget {
  final Widget child;

  const BudgetAlertWatcher({super.key, required this.child});

  @override
  ConsumerState<BudgetAlertWatcher> createState() =>
      _BudgetAlertWatcherState();
}

class _BudgetAlertWatcherState extends ConsumerState<BudgetAlertWatcher> {
  /// 上次提醒时的支出金额，用于避免重复提醒
  double _lastAlertedTotal = -1;

  /// 预算提醒开关是否开启
  bool _alertEnabled = false;

  /// 当月的总预算金额（null 表示未设置预算）
  double? _budgetAmount;

  @override
  void initState() {
    super.initState();
    // 异步读取提醒开关和预算数据
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsDao = ref.read(settingsDaoProvider);
    final budgetDao = ref.read(budgetDaoProvider);
    final now = DateTime.now();

    // 读取预算提醒开关
    final alertValue = await settingsDao.get('budget_alert');
    if (mounted) {
      setState(() => _alertEnabled = alertValue == 'true');
    }

    // 读取当前月预算（复用已有 DAO）
    final budget = await budgetDao.getMonthly(now.year, now.month);
    if (mounted) {
      setState(() => _budgetAmount = budget?.amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 复用 ui_providers 中已有的月度统计流（响应式）
    final currentMonth = DateTime(now.year, now.month, 1);

    // 监听月度支出汇总（每当数据库有交易变动时自动触发）
    ref.listen<AsyncValue<MonthlySummary>>(
      monthlyStatsProvider(currentMonth),
      (previous, next) {
        next.whenOrNull(
          data: (summary) {
            _checkBudget(summary);
          },
        );
      },
    );

    return widget.child;
  }

  /// 检查是否超预算，超则弹出提醒
  void _checkBudget(MonthlySummary summary) {
    // 条件一：提醒开关必须开启
    if (!_alertEnabled) return;
    // 条件二：必须设置了预算
    if (_budgetAmount == null || _budgetAmount! <= 0) return;
    // 条件三：当前支出必须超过预算
    if (summary.totalExpense <= _budgetAmount!) return;
    // 条件四：避免同一个阈值重复提醒
    if (summary.totalExpense == _lastAlertedTotal) return;

    // 标记已提醒，避免重复弹出
    _lastAlertedTotal = summary.totalExpense;

    // 计算超支比例
    final overRatio =
        (summary.totalExpense / _budgetAmount! - 1) * 100;
    final l10n = AppLocalizations.of(context);
    final message = overRatio > 50
        ? '${l10n.monthOverspentLabel} ${overRatio.toStringAsFixed(0)}%！'
        : '${l10n.monthOverspentLabel}！';

    // 从顶部弹出磨砂玻璃通知
    // 使用 rootNavigatorKey 获取 Overlay（BudgetAlertWatcher 位于 MaterialApp 上方，
    // 直接使用 context 无法找到 Overlay）
    final navigatorState = rootNavigatorKey.currentState;
    TopNotification.show(
      context,
      message: message,
      type: TopNotificationType.warning,
      overlay: navigatorState?.overlay,
    );
  }
}
