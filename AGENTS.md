# Timi — Expense Tracking App

## 技术栈
- Flutter + Riverpod 2.x (状态管理) + GoRouter (路由)
- drift ORM (数据库) + build_runner (代码生成)
- phosphor_flutter 2.1.0 (图标), fl_chart (图表), Google Fonts Inter, flutter_animate (动画)
- 设计: 暗色毛玻璃 (dark glassmorphism)

## 项目约束
- [工作流铁律](.opencode\rules\工作流铁律.md) 。
- [Flutter开发规范](.opencode\rules\Flutter开发规范.md)。


## 关键命令
```bash
flutter analyze          # 主验证手段，必须通过
flutter test             # 测试
flutter pub run build_runner build --delete-conflicting-outputs  # drift 代码生成
```

## 编码规范
- **导入必须使用 `package:timi/`**，禁止 `../../` 相对路径
- 所有代码必须加中文注释（非尾注）
- 所有现有文件已通过 `flutter analyze`（0 error, 0 warning）

## 架构
- `lib/main.dart` → `ProviderScope` → `TimiApp`
- `lib/core/router/app_router.dart`: `appRouterProvider` (GoRouter)，4 标签导航 (StatefulShellRoute) + 9 个 push 路由
- `lib/core/theme/app_theme.dart`: `AppTheme` 类，暗色主题，`glassDecoration()` 工具函数
- `lib/providers/database_provider.dart`: DAO 注入，`lib/providers/ui_providers.dart`: 业务状态
- `lib/data/database/`: 5 表 (CategoriesTable, TransactionsTable, BudgetsTable, CategoryBudgetsTable, SettingsTable) + 4 DAO (transaction, category, budget, settings)
- `lib/ui/shared/widgets/`: GlassCard, GlassHeader, GlassButton, EmptyState, ScaffoldWithNavBar

## 注意事项
- drift DataClass 命名: `TransactionsTableData`, `CategoriesTableData` 等（表名 + `TableData` 后缀）
- phosphor_flutter 2.1.0 按风格分 class: `PhosphorIconsLight.xxx`, `PhosphorIconsFill.xxx`
- 修改 drift 表/DAO 后必须重新运行 build_runner
- 数据库文件: `tmmi.db` (app documents 目录)
- 项目未使用 git，无版本控制
- Windows PowerShell 不支持 `&&`，用 `; if ($?) { }` 链式命令
- 写 UTF-8 文件: 使用 `write` 工具（避免 PowerShell 的 UTF-16LE 问题）
