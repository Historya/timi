import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/ui/shared/icon_helpers.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

/// 分类添加/编辑表单页面
///
/// 无 id 参数时为添加模式，有 id 参数时为编辑模式。
class CategoryFormScreen extends ConsumerStatefulWidget {
  final int? id;

  const CategoryFormScreen({super.key, this.id});

  @override
  ConsumerState<CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _nameController = TextEditingController();

  // 表单字段状态
  String _selectedType = 'expense';
  String _selectedIcon = 'food';
  String _selectedColor = '#FF6B6B';

  // 加载/保存状态
  bool _isLoading = false;
  bool _isSaving = false;

  // 编辑模式下保存原始数据，用于提交时携带原 createdAt
  CategoriesTableData? _category;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loadCategory();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 编辑模式：根据 id 加载已有分类数据
  Future<void> _loadCategory() async {
    setState(() => _isLoading = true);
    try {
      final dao = ref.read(categoryDaoProvider);
      final category = await dao.getById(widget.id!);
      if (category != null && mounted) {
        setState(() {
          _category = category;
          _nameController.text = category.name;
          _selectedType = category.type;
          _selectedIcon = category.icon;
          _selectedColor = category.color;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 保存分类（添加或更新）
  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    // 校验名称不能为空
    if (_nameController.text.trim().isEmpty) {
      TopNotification.show(context,
          message: l10n.enterCategoryName, type: TopNotificationType.warning);
      return;
    }

    // 加载或保存中禁止重复提交
    if (_isLoading || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final dao = ref.read(categoryDaoProvider);
      final now = DateTime.now();
      final name = _nameController.text.trim();

      if (widget.id != null) {
        // 编辑模式：更新已有分类
        await dao.update(CategoriesTableCompanion(
          id: Value(widget.id!),
          name: Value(name),
          icon: Value(_selectedIcon),
          color: Value(_selectedColor),
          type: Value(_selectedType),
          sortOrder: Value(_category?.sortOrder ?? 0),
          createdAt: Value(_category?.createdAt ?? now),
          updatedAt: Value(now),
        ));
      } else {
        // 添加模式：新建分类
        await dao.insert(CategoriesTableCompanion(
          name: Value(name),
          icon: Value(_selectedIcon),
          color: Value(_selectedColor),
          type: Value(_selectedType),
          sortOrder: Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
      }

      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditMode = widget.id != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 头部：返回 + 标题 + 保存按钮
            _buildHeader(context, isEditMode, l10n),
            // 表单内容（加载中时显示 loading）
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 名称输入
                          _buildNameField(context, l10n),
                          const SizedBox(height: 20),
                          // 2. 类型选择
                          _buildTypeToggle(context, isEditMode, l10n),
                          const SizedBox(height: 20),
                          // 3. 图标选择器
                          _buildIconPicker(context, l10n),
                          const SizedBox(height: 20),
                          // 4. 颜色选择器
                          _buildColorPicker(context, l10n),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建页面头部
  Widget _buildHeader(BuildContext context, bool isEditMode, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              PhosphorIconsLight.arrowLeft,
              color: AppTheme.textOnSurface(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          Expanded(
            child: Text(
              isEditMode ? l10n.editCategory : l10n.newCategory,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textOnSurface(context),
              ),
            ),
          ),
          // 保存按钮
          GestureDetector(
            onTap: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textOnSurface(context),
                    ),
                  )
                : Text(
                    l10n.save,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建名称输入框
  Widget _buildNameField(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: AppTheme.glassDecoration(
        radius: 12,
        fill: AppTheme.glassFillStrong(context),
        stroke: AppTheme.glassStroke(context),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _nameController,
        style: TextStyle(
          color: AppTheme.textOnSurface(context),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: l10n.categoryName,
          hintStyle: TextStyle(
            color: AppTheme.textOnSurfaceSecondary(context),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// 构建类型切换分段控件
  Widget _buildTypeToggle(BuildContext context, bool isEditMode, AppLocalizations l10n) {
    final segments = [
      ('expense', l10n.expenseLabel),
      ('income', l10n.incomeLabel),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.glassFillStrong(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: segments.map((entry) {
            final type = entry.$1;
            final label = entry.$2;
            final isActive = _selectedType == type;
            return Expanded(
              child: GestureDetector(
                onTap: isEditMode ? null : () => setState(() => _selectedType = type),
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
                      color: isEditMode
                          ? (isActive
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white)
                              : AppTheme.textOnSurface(context).withValues(alpha: 0.3))
                          : (isActive
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white)
                              : AppTheme.textOnSurface(context).withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建图标选择器（横向滚动网格，5 行）
  Widget _buildIconPicker(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectIcon,
          style: TextStyle(
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 72,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: categoryIconNames.length,
          itemBuilder: (context, index) {
            final iconName = categoryIconNames[index];
            final selected = _selectedIcon == iconName;
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = iconName),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: selected
                        ? parseHexColor(_selectedColor).withValues(alpha: 0.3)
                        : AppTheme.glassFill(context),
                    borderRadius: BorderRadius.circular(14),
                    border: selected
                        ? Border.all(
                            color: parseHexColor(_selectedColor),
                            width: 2,
                          )
                        : Border.all(
                            color: AppTheme.glassStroke(context),
                            width: 1,
                          ),
                  ),
                  child: Icon(
                    resolveCategoryIcon(iconName),
                    color: selected
                        ? parseHexColor(_selectedColor)
                        : AppTheme.textOnSurface(context).withValues(alpha: 0.54),
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 构建颜色选择器（颜色圆圈行）
  Widget _buildColorPicker(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectColor,
          style: TextStyle(
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categoryColorHexes.map((hex) {
            final color = parseHexColor(hex);
            final selected = _selectedColor == hex;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = hex),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(
                          color: AppTheme.textOnSurface(context),
                          width: 2.5,
                        )
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(
                        PhosphorIconsLight.check,
                        color: AppTheme.textOnSurface(context),
                        size: 18,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
