// 添加交易页面 - 毛玻璃风格记账录入界面

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/ui/shared/icon_helpers.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

/// 添加/编辑交易页面
///
/// [initialType] 初始交易类型，可选 'expense' 或 'income'，默认 'expense'
/// [existingTransaction] 传入时为编辑模式，预填表单并更新已有交易
class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType;
  final TransactionsTableData? existingTransaction;

  const AddTransactionScreen({
    super.key,
    this.initialType,
    this.existingTransaction,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController(text: '');
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();
  late String _type;
  CategoriesTableData? _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // 编辑模式：用已有交易数据预填表单
    final existing = widget.existingTransaction;
    if (existing != null) {
      _type = existing.type;
      _amountController.text = existing.amount.toStringAsFixed(2);
      _noteController.text = existing.note ?? '';
      _selectedDate = existing.date;
      // 异步加载分类列表并选中当前分类
      WidgetsBinding.instance.addPostFrameCallback((_) => _preselectCategory(existing.categoryId));
    } else {
      // 新建模式：从外部参数初始化交易类型
      _type = widget.initialType ?? 'expense';
      _selectedDate = DateTime.now();
    }
  }

  /// 根据分类 ID 异步选中对应分类
  Future<void> _preselectCategory(int categoryId) async {
    final categories = await ref.read(categoryDaoProvider).getAll();
    final match = categories.where((c) => c.id == categoryId).firstOrNull;
    if (match != null && mounted) {
      setState(() => _selectedCategory = match);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _setQuickAmount(String value) {
    _amountController.text = value;
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      TopNotification.show(
        context,
        message: '请输入金额',
        type: TopNotificationType.warning,
      );
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      TopNotification.show(
        context,
        message: '请输入有效金额',
        type: TopNotificationType.warning,
      );
      return;
    }
    if (_selectedCategory == null) {
      TopNotification.show(
        context,
        message: '请选择分类',
        type: TopNotificationType.warning,
      );
      return;
    }

    final now = DateTime.now();
    final dao = ref.read(transactionDaoProvider);

    if (widget.existingTransaction != null) {
      // 编辑模式：更新已有交易
      final updated = widget.existingTransaction!.copyWith(
        amount: amount,
        categoryId: _selectedCategory!.id,
        type: _type,
        date: _selectedDate,
        note: _noteController.text.isNotEmpty
            ? Value(_noteController.text.trim())
            : const Value.absent(),
        updatedAt: now,
      );
      await dao.update(updated.toCompanion(true));
    } else {
      // 新建模式：插入新交易
      await dao.insert(
        TransactionsTableCompanion.insert(
          amount: amount,
          categoryId: _selectedCategory!.id,
          type: _type,
          date: _selectedDate,
          note: _noteController.text.isNotEmpty
              ? Value(_noteController.text.trim())
              : const Value.absent(),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // 支出类型时查询当月预算剩余额度并弹出通知
    if (_type == 'expense' && mounted) {
      await _showBudgetRemainingNotification();
    }

    if (mounted) {
      if (widget.existingTransaction != null) {
        // 编辑模式：返回主页（从详情页 "编辑" 跳转后，编辑完成回首页）
        context.go('/');
      } else {
        // 新建模式：返回上一个页面
        context.pop();
      }
    }
  }

  /// 查询当月预算剩余额度，通过顶部通知弹窗展示
  Future<void> _showBudgetRemainingNotification() async {
    final budgetDao = ref.read(budgetDaoProvider);
    final transactionDao = ref.read(transactionDaoProvider);

    // 查询当月是否设置了预算
    final budget = await budgetDao.getMonthly(
      _selectedDate.year,
      _selectedDate.month,
    );
    if (budget == null) return; // 未设置预算，不弹出通知

    // 查询当月总支出（包含刚添加的账单）
    final totalExpense = await transactionDao.getMonthlyTotalByType(
      _selectedDate.year,
      _selectedDate.month,
      'expense',
    );

    // 计算预算剩余额度（负数表示超支）
    final remaining = budget.amount - totalExpense;

    if (!mounted) return;

    if (remaining >= 0) {
      // 预算还有剩余，显示绿色提醒
      TopNotification.show(
        context,
        message: '本月预算剩余 ¥${remaining.toStringAsFixed(0)}',
        type: TopNotificationType.success,
      );
    } else {
      // 已超支，显示警告提醒
      TopNotification.show(
        context,
        message: '本月预算已超支 ¥${(-remaining).toStringAsFixed(0)}',
        type: TopNotificationType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(_type));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      _buildTypeToggle(context),
                      const SizedBox(height: 20),
                      _buildAmountCard(context),
                      const SizedBox(height: 20),
                      _buildCategorySection(categoriesAsync, context),
                      const SizedBox(height: 20),
                      _buildNoteInput(context),
                      const SizedBox(height: 24),
                      _buildSaveButton(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据当前模式（编辑/新建）和交易类型返回页面标题
  String _buildTitle() {
    if (widget.existingTransaction != null) {
      return _type == 'expense' ? '编辑支出' : '编辑收入';
    }
    return _type == 'expense' ? '添加支出' : '添加收入';
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            '取消',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            _buildTitle(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context),
            ),
          ),
        ),
        GestureDetector(
          onTap: _save,
          child: Text(
            '完成',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggle(BuildContext context) {
    final isExpense = _type == 'expense';
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassFillStrong(context),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = 'expense'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isExpense
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '支出',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isExpense
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white)
                        : AppTheme.textOnSurfaceTertiary(context),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = 'income'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isExpense
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '收入',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: !isExpense
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white)
                        : AppTheme.textOnSurfaceTertiary(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecorationFull(context: context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '金额',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textOnSurfaceTertiary(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '¥',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textOnSurface(context),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOnSurface(context),
                      height: 1.0,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textOnSurface(
                          context,
                        ).withValues(alpha: 0.24),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickAmountButton(
                label: '50',
                onTap: () => _setQuickAmount('50'),
              ),
              const SizedBox(width: 8),
              _QuickAmountButton(
                label: '100',
                onTap: () => _setQuickAmount('100'),
              ),
              const SizedBox(width: 8),
              _QuickAmountButton(
                label: '200',
                onTap: () => _setQuickAmount('200'),
              ),
              const SizedBox(width: 8),
              _QuickAmountButton(
                label: '500',
                onTap: () => _setQuickAmount('500'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    AsyncValue<List<CategoriesTableData>> categoriesAsync,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择分类',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textOnSurface(context),
          ),
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    '暂无分类，请先在分类管理中创建',
                    style: TextStyle(
                      color: AppTheme.textOnSurface(
                        context,
                      ).withValues(alpha: 0.38),
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }
            final displayList = categories.length > 8
                ? categories.sublist(0, 8)
                : categories;
            return Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final cat = displayList[index];
                    final isSelected = _selectedCategory?.id == cat.id;
                    return _CategoryGridCell(
                      category: cat,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // "管理分类" 按钮，跳转到分类管理页面
                GestureDetector(
                  onTap: () => context.push('/categories'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.glassFillStrong(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsLight.plusCircle,
                          size: 16,
                          color: AppTheme.textOnSurface(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '管理分类',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textOnSurface(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                color: AppTheme.textOnSurface(context).withValues(alpha: 0.54),
              ),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
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
      ],
    );
  }

  Widget _buildNoteInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassFillStrong(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassStroke(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(
            PhosphorIconsLight.note,
            size: 18,
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _noteController,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textOnSurface(context),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '添加备注...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textOnSurface(context).withValues(alpha: 0.4),
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: _save,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.glassFillAccent(context),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.glassStroke(context)),
        ),
        child: Center(
          child: Text(
            '保存',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// 分类网格单元格：48×48 圆形图标 + 底部名称
class _CategoryGridCell extends StatelessWidget {
  final CategoriesTableData category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryGridCell({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = parseHexColor(category.color);
    final bgColor = catColor.withValues(alpha: 0.2);
    final borderColor = isSelected ? catColor : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Icon(
              resolveCategoryIcon(category.icon),
              color: catColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 快捷金额药丸按钮：60×32，圆角 16
class _QuickAmountButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.glassFillStrong(context),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textOnSurface(context),
          ),
        ),
      ),
    );
  }
}
