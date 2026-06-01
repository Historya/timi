// 预算页面 — 内联编辑，点击即改，所见即所得
//
// 包含：预算总览卡片（可编辑的月度预算金额、进度条、已用/剩余统计）
// 和分类预算卡片（各分类预算与实际花费对比）
//
// 设计原则：所有编辑在页面上直接完成，不弹出任何 Modal。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/ui/shared/icon_helpers.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  /// 是否处于编辑模式（显示保存/取消按钮）
  bool _isEditing = false;

  /// 编辑中的总预算金额
  late TextEditingController _totalBudgetCtrl;

  /// 各分类预算金额控制器
  final Map<int, TextEditingController> _categoryCtrls = {};

  /// 是否已完成初始化（避免重复填充数据）
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _totalBudgetCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _totalBudgetCtrl.dispose();
    for (final ctrl in _categoryCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  /// 用 [MonthlyBudgetData] 填充编辑控制器
  void _initControllers(MonthlyBudgetData data) {
    if (_initialized) return;
    _totalBudgetCtrl.text = data.totalBudget.toStringAsFixed(0);
    for (final cb in data.categoryBudgets) {
      if (!_categoryCtrls.containsKey(cb.category.id)) {
        _categoryCtrls[cb.category.id] = TextEditingController(
          text: cb.budgetAmount > 0 ? cb.budgetAmount.toStringAsFixed(0) : '',
        );
      }
    }
    _initialized = true;
  }

  /// 保存所有预算修改（总预算 + 分类预算）
  Future<void> _saveBudget() async {
    final now = DateTime.now();
    final budgetDao = ref.read(budgetDaoProvider);

    // 1) 保存总预算
    final totalText = _totalBudgetCtrl.text.trim();
    if (totalText.isNotEmpty) {
      final totalAmount = double.tryParse(totalText);
      if (totalAmount != null && totalAmount > 0) {
        await budgetDao.upsertMonthlyBudget(
          amount: totalAmount,
          year: now.year,
          month: now.month,
        );
      }
    }

    // 2) 保存各分类预算（使用 upsert 避免重复行）
    final existing = await budgetDao.getMonthly(now.year, now.month);
    if (existing != null) {
      for (final entry in _categoryCtrls.entries) {
        final text = entry.value.text.trim();
        if (text.isNotEmpty) {
          final amount = double.tryParse(text);
          if (amount != null && amount > 0) {
            await budgetDao.upsertCategoryBudget(
              budgetId: existing.id,
              categoryId: entry.key,
              amount: amount,
            );
          }
        }
      }
    }

    // 3) 刷新 FutureProvider 缓存，使 UI 显示最新数据
    ref.invalidate(
      monthlyBudgetProvider((year: now.year, month: now.month)),
    );

    if (mounted) {
      setState(() {
        _isEditing = false;
        _initialized = false; // 下一轮 build 从刷新后的数据重新初始化
      });
    }
  }

  /// 取消编辑，重置所有字段
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _initialized = false; // 重新从数据库加载
    });
  }

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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final month = ref.watch(currentMonthProvider);
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
                      return _buildEmptyState(context);
                    }
                    _initControllers(budgetData);
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
                          const SizedBox(height: 24),
                          // 编辑模式下显示保存按钮
                          if (_isEditing) _buildSaveButton(context),
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
                      child: Text('${l10n.loadFailed}: $e'),
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

  /// 头部：返回 + 标题 + 编辑/取消按钮
  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            l10n.budgetSettings,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const Spacer(),
          // 编辑/取消按钮
          GestureDetector(
            onTap: () {
              setState(() {
                if (_isEditing) {
                  _cancelEdit();
                } else {
                  _isEditing = true;
                }
              });
            },
            child: Text(
              _isEditing ? l10n.cancel : l10n.edit,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _isEditing
                    ? AppTheme.textOnSurface(context).withValues(alpha: 0.6)
                    : AppTheme.accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "分类预算" 标题
  Widget _buildSectionTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        l10n.categoryBudget,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            l10n.noBudgetSet,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          // 空状态直接显示输入框 + 保存按钮
          _buildEmptyBudgetInput(context),
        ],
      ),
    );
  }

  /// 空状态的预算输入
  Widget _buildEmptyBudgetInput(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppTheme.glassDecorationFull(
            context: context,
            radius: 16,
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // 金额输入
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textOnSurface(context),
                ),
                decoration: InputDecoration(
                  prefixText: '¥ ',
                  prefixStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnSurface(context),
                  ),
                  hintText: l10n.enterMonthlyBudget,
                  hintStyle: TextStyle(
                    fontSize: 20,
                    color: AppTheme.textOnSurface(context)
                        .withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),
              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    final amount = double.tryParse(text);
                    if (amount == null || amount <= 0) return;
                    final now = DateTime.now();
                    await ref.read(budgetDaoProvider).upsertMonthlyBudget(
                          amount: amount,
                          year: now.year,
                          month: now.month,
                        );
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.setBudget,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  /// 预算总览卡片
  Widget _buildBudgetOverview(
    BuildContext context,
    MonthlyBudgetData data,
  ) {
    final l10n = AppLocalizations.of(context);
    // 计算剩余金额
    final remaining = data.totalBudget - data.totalSpent;
    // 计算进度占比
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
          Row(
            children: [
              Text(
                l10n.monthlyBudget,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
                ),
              ),
              if (!_isEditing)
                GestureDetector(
                  onTap: () => setState(() => _isEditing = true),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      PhosphorIconsLight.pencilSimple,
                      size: 16,
                      color: AppTheme.textOnSurface(context)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 总预算金额 —— 编辑模式下显示输入框，否则显示文字
          _isEditing
              ? TextField(
                  controller: _totalBudgetCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnSurface(context),
                  ),
                  decoration: InputDecoration(
                    prefixText: '¥ ',
                    prefixStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOnSurface(context),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  '¥ ${_formatCurrency(data.totalBudget)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnSurface(context),
                  ),
                ),
          const SizedBox(height: 12),
          // 进度条
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
                          child: Container(color: AppTheme.glassFillStrong(context)),
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
                  '${l10n.used} ¥${_formatCurrency(data.totalSpent, decimals: 0)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textOnSurface(context),
                ),
              ),
              const Spacer(),
              Text(
                '${l10n.remaining} ¥${_formatCurrency(remaining, decimals: 0)}',
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

  /// 分类预算卡片
  Widget _buildCategoryBudgetCard(
    BuildContext context,
    MonthlyBudgetData data,
  ) {
    final l10n = AppLocalizations.of(context);
    final list = data.categoryBudgets;
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: AppTheme.glassDecoration(
          radius: 16,
          fill: AppTheme.glassFillStrong(context),
          context: context,
        ),
        child: Center(
          child: Text(
            l10n.noCategoryBudget,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

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
              return Divider(
                height: 1,
                color: AppTheme.glassStroke(context),
            );
          }
          final cat = list[index ~/ 2];
          return _buildCategoryRow(context, cat);
        }),
      ),
    );
  }

  /// 单行分类：图标 + 名称 + 进度条 + 金额（可编辑）
  Widget _buildCategoryRow(
    BuildContext context,
    CategoryBudgetWithSpending cat,
  ) {
    final ratio = cat.budgetAmount > 0
        ? (cat.actualSpent / cat.budgetAmount).clamp(0.0, 1.0)
        : 0.0;
    final ctrl = _categoryCtrls[cat.category.id];

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
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 64,
              height: 4,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 4,
                    color: AppTheme.glassFillStrong(context),
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
          // 金额 —— 编辑模式显示输入框，否则显示文字
          _isEditing && ctrl != null
              ? SizedBox(
                  width: 80,
                  height: 32,
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textOnSurface(context),
                    ),
                    decoration: InputDecoration(
                      prefixText: '¥',
                      prefixStyle: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textOnSurface(context)
                            .withValues(alpha: 0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.glassStroke(context),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      isDense: true,
                    ),
                  ),
                )
              : Text(
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

  /// 底部的保存按钮（编辑模式）
  Widget _buildSaveButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _saveBudget,
        icon: const Icon(PhosphorIconsFill.check, size: 20),
        label: Text(
          l10n.saveBudget,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGreen,
          foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
