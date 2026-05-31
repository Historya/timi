// 账单详情页面
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/ui/shared/icon_helpers.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

/// 账单详情页包装数据
class BillDetailData {
  final TransactionsTableData transaction;
  final CategoriesTableData category;

  BillDetailData({required this.transaction, required this.category});
}

/// 按 id 加载账单详情及关联分类
final billDetailProvider = FutureProvider.autoDispose
    .family<BillDetailData, int>((ref, id) async {
      final transaction = await ref.read(transactionDaoProvider).getById(id);
      final categories = await ref.read(categoryDaoProvider).getAll();
      final categoryMap = {for (final c in categories) c.id: c};
      final category = categoryMap[transaction.categoryId]!;
      return BillDetailData(transaction: transaction, category: category);
    });

/// 格式化日期："1月15日 14:30"
String _formatDate(DateTime dt) {
  return '${dt.month}月${dt.day}日 '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// 类型中文映射
String _typeLabel(String type) => type == 'income' ? '收入' : '支出';

class BillDetailScreen extends ConsumerWidget {
  final int id;

  const BillDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(billDetailProvider(id));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '加载失败：$e',
                  style: TextStyle(
                    color: AppTheme.textOnSurface(
                      context,
                    ).withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (data) => _buildContent(context, ref, data),
          ),
        ),
      ),
    );
  }

  /// 构建主体内容
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    BillDetailData data,
  ) {
    final txn = data.transaction;
    final cat = data.category;
    return Column(
      children: [
        const _Header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _CategoryIconArea(iconName: cat.icon, colorHex: cat.color),
                const SizedBox(height: 12),
                _AmountText(amount: txn.amount, type: txn.type),
                const SizedBox(height: 4),
                _CategoryLabel(name: cat.name),
                const SizedBox(height: 16),
                _DetailCard(
                  categoryName: cat.name,
                  date: txn.date,
                  typeLabel: _typeLabel(txn.type),
                  note: txn.note,
                ),
                const SizedBox(height: 24),
                _ActionButtons(
                  onDelete: () {
                    if (txn.date.month != DateTime.now().month) {
                      TopNotification.show(
                        context,
                        message: '该账目不在记账期间内',
                        type: TopNotificationType.warning,
                      );
                      return;
                    }
                    _delete(context, ref, txn.id);
                  },
                  onEdit: () {
                    if (txn.date.month != DateTime.now().month) {
                      TopNotification.show(
                        context,
                        message: '该账目不在记账期间内',
                        type: TopNotificationType.warning,
                      );
                      return;
                    }
                    context.push(
                      '/add-transaction',
                      extra: {'transaction': data.transaction},
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 删除确认弹窗
  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        title: Text(
          '删除交易',
          style: TextStyle(color: AppTheme.textOnSurface(context)),
        ),
        content: Text(
          '确定要删除这笔交易吗？',
          style: TextStyle(
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '取消',
              style: TextStyle(
                color: AppTheme.textOnSurface(context).withValues(alpha: 0.54),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(transactionDaoProvider).delete(id);
      if (context.mounted) context.pop();
    }
  }
}

/// 顶部导航栏：返回箭头 + 标题 + 更多菜单
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              PhosphorIconsLight.arrowLeft,
              color: AppTheme.textOnSurface(context),
              size: 24,
            ),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              '账单详情',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textOnSurface(context),
              ),
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// 分类图标区域：72×72 圆角矩形 + 分类图标
class _CategoryIconArea extends StatelessWidget {
  final String iconName;
  final String colorHex;

  const _CategoryIconArea({required this.iconName, required this.colorHex});

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(colorHex);
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(resolveCategoryIcon(iconName), size: 32, color: color),
      ),
    );
  }
}

/// 金额文本：支出红色 / 收入绿色
class _AmountText extends StatelessWidget {
  final double amount;
  final String type;

  const _AmountText({required this.amount, required this.type});

  @override
  Widget build(BuildContext context) {
    final isExpense = type == 'expense';
    final sign = isExpense ? '-' : '+';
    final color = isExpense ? const Color(0xFFF87171) : const Color(0xFF4ADE80);
    return Text(
      '$sign¥${amount.toStringAsFixed(2)}',
      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
      textAlign: TextAlign.center,
    );
  }
}

/// 分类标签
class _CategoryLabel extends StatelessWidget {
  final String name;

  const _CategoryLabel({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: TextStyle(
        fontSize: 16,
        color: AppTheme.textOnSurfaceTertiary(context),
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// 详情毛玻璃卡片：分类 / 日期 / 类型 / 备注
class _DetailCard extends StatelessWidget {
  final String categoryName;
  final DateTime date;
  final String typeLabel;
  final String? note;

  const _DetailCard({
    required this.categoryName,
    required this.date,
    required this.typeLabel,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final hasNote = note != null && note!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecorationFull(context: context, radius: 20),
      child: Column(
        children: [
          _DetailRow(label: '分类', value: categoryName),
          Divider(height: 1, color: AppTheme.glassFillStrong(context)),
          _DetailRow(label: '日期', value: _formatDate(date)),
          Divider(height: 1, color: AppTheme.glassFillStrong(context)),
          _DetailRow(label: '类型', value: typeLabel),
          // 有备注时添加备注行
          if (hasNote) ...[
            Divider(height: 1, color: AppTheme.glassFillStrong(context)),
            _DetailRow(label: '备注', value: note!, isLongText: true),
          ],
        ],
      ),
    );
  }
}

/// 详情卡片中的单行：标签 + 值
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLongText;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLongText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: isLongText
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textOnSurfaceTertiary(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textOnSurface(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// 操作按钮行：删除 + 编辑
class _ActionButtons extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const _ActionButtons({required this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onDelete,
          child: Container(
            width: 120,
            height: 48,
            decoration: AppTheme.glassDecoration(
              radius: 24,
              fill: AppTheme.glassFillStrong(context),
              context: context,
            ),
            child: const Center(
              child: Text(
                '删除',
                style: TextStyle(color: Color(0xFFF87171), fontSize: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onEdit ?? () {},
          child: Container(
            width: 140,
            height: 48,
            decoration: AppTheme.glassDecoration(
              radius: 24,
              fill: AppTheme.glassFillAccent(context),
              context: context,
            ),
            child: Center(
              child: Text(
                '编辑',
                style: TextStyle(
                  color: AppTheme.textOnSurface(context),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
