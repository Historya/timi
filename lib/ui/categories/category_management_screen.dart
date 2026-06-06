// 分类管理页面
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:timi/ui/shared/icon_helpers.dart';

/// 分类管理页面
class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  /// 当前选中的分类类型：expense / income
  String _selectedType = 'expense';

  /// 显示分类操作菜单（编辑/删除）
  void _showCategoryOptions(BuildContext context, CategoriesTableData cat) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.textOnSurface(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textOnSurface(context),
              ),
            ),
            const SizedBox(height: 24),
            // 编辑按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/categories/edit/${cat.id}');
                },
                icon: const Icon(PhosphorIconsLight.pencil),
                label: Text(l10n.editCategory),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.glassFillStrong(context),
                  foregroundColor: AppTheme.textOnSurface(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 删除按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(context, cat);
                },
                icon: const Icon(PhosphorIconsLight.trash),
                label: Text(l10n.deleteCategory),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0x33F87171),
                  foregroundColor: const Color(0xFFF87171),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 确认删除分类（先检查是否有交易引用）
  Future<void> _confirmDelete(BuildContext context, CategoriesTableData cat) async {
    final l10n = AppLocalizations.of(context);
    final transactionDao = ref.read(transactionDaoProvider);
    final count = await transactionDao.countByCategoryId(cat.id);
    if (!context.mounted) return;

    if (count > 0) {
      // 有交易引用，无法删除
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text(
            l10n.cannotDelete,
            style: TextStyle(color: AppTheme.textOnSurface(ctx)),
          ),
          content: Text(
            l10n.cannotDeleteHint(count),
            style: TextStyle(color: AppTheme.textOnSurfaceSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    } else {
      // 无交易引用，确认删除
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text(
            l10n.confirmDelete,
            style: TextStyle(color: AppTheme.textOnSurface(ctx)),
          ),
          content: Text(
            l10n.confirmDeleteCategory(cat.name),
            style: TextStyle(color: AppTheme.textOnSurfaceSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: AppTheme.textOnSurfaceTertiary(context)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.delete, style: const TextStyle(color: Color(0xFFF87171))),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        await ref.read(categoryDaoProvider).delete(cat.id);
      }
    }
  }

  /// 处理分类拖拽排序
  Future<void> _onReorder(List<CategoriesTableData> items, int oldIndex, int newIndex) async {
    // ReorderableListView 在向下拖拽时 newIndex 会 +1，需要修正
    if (oldIndex < newIndex) newIndex -= 1;

    final movedItem = items[oldIndex];
    final List<CategoriesTableData> reordered = List.from(items)
      ..removeAt(oldIndex)
      ..insert(newIndex, movedItem);

    // 批量更新 sortOrder
    final categoryDao = ref.read(categoryDaoProvider);
    for (int i = 0; i < reordered.length; i++) {
      if (reordered[i].sortOrder != i) {
        await categoryDao.updateSortOrder(reordered[i].id, i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 按类型监听分类数据流
    final categoriesAsync = ref.watch(categoriesByTypeProvider(_selectedType));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle(context),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(l10n: l10n),
              const SizedBox(height: 10),
              _TypeToggle(
                selectedType: _selectedType,
                onChanged: (type) => setState(() => _selectedType = type),
                l10n: l10n,
              ),
              const SizedBox(height: 10),
              const _HintText(),
              const SizedBox(height: 10),
              Expanded(
                child: categoriesAsync.when(
                  // 数据加载成功，渲染分类列表
                  data: (categories) {
                    if (categories.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.noCategoriesYet,
                          style: TextStyle(
                            color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
                          ),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (_selectedType == 'expense')
                          _CategoryGlassCard(
                            categories: categories,
                            onLongPress: (cat) => _showCategoryOptions(context, cat),
                            onReorder: (oldIndex, newIndex) => _onReorder(categories, oldIndex, newIndex),
                          )
                        else ...[
                          const _IncomeSectionHeader(),
                          const SizedBox(height: 8),
                          _CategoryGlassCard(
                            categories: categories,
                            onLongPress: (cat) => _showCategoryOptions(context, cat),
                            onReorder: (oldIndex, newIndex) => _onReorder(categories, oldIndex, newIndex),
                          ),
                        ],
                      ],
                    );
                  },
                  // 加载中状态
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  // 加载失败状态
                  error: (e, _) => Center(
                    child: Text(l10n.loadFailed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 头部：返回按钮 + 分类管理标题 + 添加按钮
class _Header extends StatelessWidget {
  final AppLocalizations l10n;

  const _Header({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              PhosphorIconsLight.arrowLeft,
              color: AppTheme.textOnSurface(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.categoryManagement,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textOnSurface(context),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/categories/add'),
            child: Container(
              width: 36,
              height: 36,
              decoration: AppTheme.glassDecoration(
                radius: 18,
                fill: AppTheme.glassFillAccent(context),
                context: context,
              ),
              child: Icon(
                PhosphorIconsLight.plus,
                color: AppTheme.textOnSurface(context),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 支出/收入类型切换分段控制器
class _TypeToggle extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;
  final AppLocalizations l10n;

  const _TypeToggle({
    required this.selectedType,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.glassFillStrong(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            _buildSegment('expense', l10n.expenseCategories_, context),
            _buildSegment('income', l10n.incomeCategories_, context),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String type, String label, BuildContext context) {
    final isActive = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1A1A1A))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1A1A)
                      : Colors.white)
                  : AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

/// 提示文字
class _HintText extends StatelessWidget {
  const _HintText();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        l10n.hintDragEdit,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textOnSurfaceTertiary(context),
        ),
      ),
    );
  }
}

/// 收入分类区域标题
class _IncomeSectionHeader extends StatelessWidget {
  const _IncomeSectionHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.incomeCategories_,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textOnSurface(context),
      ),
    );
  }
}

/// 分类列表卡片：支持拖拽排序
class _CategoryGlassCard extends StatelessWidget {
  final List<CategoriesTableData> categories;
  final void Function(CategoriesTableData) onLongPress;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _CategoryGlassCard({
    required this.categories,
    required this.onLongPress,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.glassDecoration(
        radius: 18,
        fill: AppTheme.glassFillStrong(context),
        context: context,
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final catColor = parseHexColor(cat.color);
          return _CategoryReorderItem(
            key: ValueKey(cat.id),
            category: cat,
            catColor: catColor,
            onTap: () => context.push('/categories/edit/${cat.id}'),
            onLongPress: () => onLongPress(cat),
          );
        },
        onReorder: onReorder,
        proxyDecorator: (child, index, animation) {
          // 拖拽时半透明效果
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Opacity(
                opacity: 0.8,
                child: child,
              );
            },
            child: child,
          );
        },
      ),
    );
  }
}

/// 可拖拽排序的分类项
class _CategoryReorderItem extends StatelessWidget {
  final CategoriesTableData category;
  final Color catColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CategoryReorderItem({
    super.key,
    required this.category,
    required this.catColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.glassFill(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // 拖拽手柄
              Icon(
                PhosphorIconsLight.list,
                size: 20,
                color: AppTheme.textOnSurface(context).withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),
              // 分类图标
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  resolveCategoryIcon(category.icon),
                  color: catColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // 分类名称
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textOnSurface(context),
                  ),
                ),
              ),
              // 右箭头
              Icon(
                PhosphorIconsLight.caretRight,
                size: 16,
                color: AppTheme.textOnSurface(context).withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
