// 分类编辑弹窗
// 返回 Map{name, icon, color} 或 null（取消）
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/ui/shared/icon_helpers.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

class EditCategoryDialog extends StatefulWidget {
  final String type;
  final String? initialName;
  final String? initialIcon;
  final String? initialColor;

  const EditCategoryDialog({
    super.key,
    required this.type,
    this.initialName,
    this.initialIcon,
    this.initialColor,
  });

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;

  static const _icons = [
    'fork-knife', 'shopping-cart', 'car', 'bus', 'airplane',
    'game-controller', 'film-slate', 'books', 'graduation-cap',
    'first-aid', 'hospital', 'heart', 'gift', 'coffee',
    'hamburger', 'cake', 'dog', 'pen', 'lightbulb', 'house',
  ];

  static const _colors = [
    '#ef4444', '#f97316', '#f59e0b', '#eab308',
    '#22c55e', '#14b8a6', '#06b6d4', '#3b82f6',
    '#6366f1', '#8b5cf6', '#a855f7', '#ec4899',
    '#78716c',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIcon ?? _icons[0];
    _selectedColor = widget.initialColor ?? _colors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      TopNotification.show(context,
          message: l10n.enterCategoryName, type: TopNotificationType.warning);
      return;
    }
    Navigator.of(context).pop({
      'name': name,
      'icon': _selectedIcon,
      'color': _selectedColor,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNew = widget.initialName == null;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.glassStroke(context)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 弹窗头部：标题 + 关闭按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isNew ? l10n.newCategory : l10n.editCategory,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      PhosphorIconsLight.x,
                      color: AppTheme.textOnSurface(context).withValues(alpha: 0.54),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 选择图标
              Text(
                l10n.selectIcon,
                style: TextStyle(
                  color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _icons.map((iconName) {
                  final selected = _selectedIcon == iconName;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = iconName),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? parseHexColor(_selectedColor).withValues(alpha: 0.4)
                            : AppTheme.glassFill(context),
                        borderRadius: BorderRadius.circular(14),
                        border: selected
                            ? Border.all(
                                color: parseHexColor(_selectedColor),
                                width: 2,
                              )
                            : null,
                      ),
                      child: Icon(
                        resolveCategoryIcon(iconName),
                        color: selected
                            ? parseHexColor(_selectedColor)
                            : AppTheme.textOnSurface(context).withValues(alpha: 0.54),
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // 分类名称
              Text(
                l10n.categoryName,
                style: TextStyle(
                  color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.glassFillStrong(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.glassStroke(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    color: AppTheme.textOnSurface(context),
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.categoryName,
                    hintStyle: TextStyle(
                      color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 分类颜色
              Text(
                l10n.selectColor,
                style: TextStyle(
                  color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((hex) {
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
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // 按钮行
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.glassFillStrong(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.glassStroke(context),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            color: AppTheme.textOnSurfaceSecondary(context),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _save,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.glassFillAccent(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.glassStroke(context),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.save,
                          style: TextStyle(
                            color: AppTheme.textOnSurface(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
