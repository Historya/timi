# 主题与共享组件

## 暗色玻璃拟态主题

- 实现类: `AppTheme` 静态类 (`lib/core/theme/app_theme.dart`)
- 渐变背景: `#4158D0 → #C850C0 → #FFCC70`
- 暗色表面: `#1A1A1A`
- 玻璃装饰: `glassDecoration()` (无阴影), `glassDecorationFull()` (带阴影)
- 主题感知颜色: `glassFill(context)`, `glassStroke(context)`, `textOnSurface(context)`
- 3 级玻璃填充: 默认 / strong / accent
- 语义色板: accentGreen, accentOrange, accentBlue, accentPurple, accentYellow
- Material 3, Google Fonts Inter

## 共享组件

| 组件 | 用途 |
|------|------|
| `GlassCard` | 毛玻璃容器 (padding, radius, fill) |
| `GlassHeader` | 标题栏, 可选返回按钮 + 右侧操作 |
| `GlassButton` | 按压动画的毛玻璃按钮 |
| `GlassStatusBar` | 静态状态栏模型 (9:41 + 图标) |
| `EmptyState` | 空状态占位 (icon, title, action button) |
| `ScaffoldWithNavBar` | 响应式导航: 手机底部胶囊 / 平板 NavigationRail |
| `TopNotification` | Overlay 悬浮通知 (替代 SnackBar) |
| `BudgetAlertWatcher` | 包裹应用, 监控预算并触发悬浮预警 |

## 图标辅助

位于 `lib/ui/shared/icon_helpers.dart`:

- `resolveCategoryIcon(String iconName)` — 字符串 → PhosphorIconData
- `parseHexColor(String hex)` — `#RRGGBB` → Color
- `categoryIconNames` / `categoryColorHexes` — 分类选择器数据

## UI 设计稿

- 各页面规格说明: [agent/design-specs.md](agent/design-specs.md)
- Pencil 原型: `ui-design/ui.pen` (+ gauge.js)
