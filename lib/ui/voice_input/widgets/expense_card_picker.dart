// 多笔账目横向卡片选择器 — 展示解析出的账目列表，点击选中、单独确认或取消

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/services/expense_parser.dart';

/// 横向排列的账目卡片列表（仅多笔账目时显示）
///
/// 类似 Android 前台任务卡片：
/// - 点击卡片 → 选中该笔账目（回调 [onSelect]）
/// - 点击卡片右上角 √ → 单独确认保存该笔（回调 [onConfirm]）
/// - 点击卡片右上角 × → 取消移除该笔（回调 [onRemove]）
class ExpenseCardPicker extends StatelessWidget {
  /// 账目列表
  final List<ParsedExpense> expenses;

  /// 当前选中的卡片下标
  final int selectedIndex;

  /// 点击卡片选中回调
  final ValueChanged<int> onSelect;

  /// 单独确认回调 — 保存该笔并从列表移除
  final ValueChanged<int> onConfirm;

  /// 取消回调 — 不保存，仅从列表移除
  final ValueChanged<int> onRemove;

  /// 卡片分类名取值回调 — 返回指定下标卡片的展示分类名
  ///
  /// 用于关联表单分类值：选中卡片返回表单当前分类，其余返回解析值。
  /// 未传入或返回空串时回退到解析原始值 / "未分类"。
  final String Function(int index)? categoryNameOf;

  /// 分类名 → 颜色回调 — 返回该分类的边框颜色
  ///
  /// 用于卡片边框跟随分类色，返回 null 时回退默认样式。
  final Color? Function(String categoryName)? categoryColorOf;

  const ExpenseCardPicker({
    super.key,
    required this.expenses,
    required this.selectedIndex,
    required this.onSelect,
    required this.onConfirm,
    required this.onRemove,
    this.categoryNameOf,
    this.categoryColorOf,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: expenses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _ExpenseCard(
          index: index,
          expense: expenses[index],
          isSelected: index == selectedIndex,
          categoryName: categoryNameOf?.call(index),
          categoryColorOf: categoryColorOf,
          onSelect: () => onSelect(index),
          onConfirm: () => onConfirm(index),
          onRemove: () => onRemove(index),
        ),
      ),
    );
  }
}

/// 单张账目卡片 — 展示分类、金额、备注，点击选中
class _ExpenseCard extends StatelessWidget {
  final int index;
  final ParsedExpense expense;
  final bool isSelected;

  /// 卡片展示的分类名（关联表单值），null/空串时回退解析值
  final String? categoryName;

  /// 分类名 → 颜色回调，边框颜色跟随分类色
  final Color? Function(String categoryName)? categoryColorOf;
  final VoidCallback onSelect;
  final VoidCallback onConfirm;
  final VoidCallback onRemove;

  const _ExpenseCard({
    required this.index,
    required this.expense,
    required this.isSelected,
    required this.onSelect,
    required this.onConfirm,
    required this.onRemove,
    this.categoryName,
    this.categoryColorOf,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = categoryName?.isNotEmpty == true
        ? categoryName!
        : expense.categoryName ?? '';
    final categoryNameText = name.isEmpty ? l10n.uncategorized : name;
    final categoryColor =
        name.isEmpty ? null : categoryColorOf?.call(name);
    final amount = expense.amount?.toStringAsFixed(2) ?? '--';
    final note = expense.note.isEmpty ? '' : expense.note;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.glassFillAccent(context)
              : AppTheme.glassFill(context),
          borderRadius: BorderRadius.circular(16),
          // 边框颜色跟随分类色：选中高亮（alpha 0.8），未选中淡化（alpha 0.35）；
          // 无分类色时保持默认样式（选中 accentBlue，未选中毛玻璃描边）
          border: Border.all(
            color: categoryColor != null
                ? categoryColor.withValues(
                    alpha: isSelected ? 0.8 : 0.35,
                  )
                : isSelected
                    ? AppTheme.accentBlue.withValues(alpha: 0.8)
                    : AppTheme.glassStroke(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 序号 + 分类名 + 单独确认按钮
            Row(
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textOnSurface(context).withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    categoryNameText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
                ),
                // 取消该卡片按钮：不保存，仅从列表移除
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.glassFillStrong(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.glassStroke(context),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      PhosphorIconsLight.x,
                      size: 12,
                      color: AppTheme.textOnSurfaceSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 单独确认按钮：保存该笔并从列表移除
                GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentBlue.withValues(alpha: 0.15)
                          : AppTheme.glassFillStrong(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentBlue.withValues(alpha: 0.6)
                            : AppTheme.glassStroke(context),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      PhosphorIconsLight.check,
                      size: 12,
                      color: isSelected
                          ? AppTheme.accentBlue
                          : AppTheme.textOnSurfaceSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 金额
            Text(
              '¥ $amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppTheme.accentBlue
                    : AppTheme.textOnSurface(context),
              ),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textOnSurfaceTertiary(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
