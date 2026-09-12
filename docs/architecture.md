# 架构与数据流

## 技术栈

| 层次 | 选型 |
|------|------|
| 框架 | Flutter (Dart SDK ^3.11.5) |
| 状态管理 | Riverpod 2.x (Provider/StreamProvider/StateProvider/NotifierProvider/FutureProvider) |
| 路由 | GoRouter 15.x (4 标签导航 + 9 push 路由) |
| 数据库 | drift ORM 2.x (SQLite, 代码生成 via build_runner) |
| 图标 | phosphor_flutter 2.1.0 |
| 图表 | fl_chart 0.70.x |
| 字体 | Google Fonts Inter |
| 动画 | flutter_animate |
| ASR | DashScope (WebSocket), 腾讯云 (预留) |
| AI 解析 | DashScope Qwen-turbo (HTTP), 规则引擎降级 |
| 国际化 | flutter_localizations + intl ARB (en, zh) |

## 应用结构

```
main.dart → ProviderScope → TimiApp (ConsumerWidget)
  ├── MaterialApp.router (GoRouter)
  │     ├── /  → ScaffoldWithNavBar (IndexedStack + currentTabIndexProvider)
  │     │     ├── HomeScreen (tab 0)       — 首页总览
  │     │     ├── BillsScreen (tab 1)      — 账单列表
  │     │     ├── StatisticsScreen (tab 2) — 消费统计
  │     │     └── ProfileScreen (tab 3)    — 个人中心
  │     └── push 路由 (rootNavigatorKey)
  │           ├── /add-transaction, /voice-input, /detail/:id
  │           ├── /categories, /categories/add, /categories/edit/:id
  │           ├── /search, /settings, /budget, /export, /about
  └── BudgetAlertWatcher (预算超支悬浮通知)
```

**数据流**: UI → Riverpod providers → DAOs → drift 查询 → SQLite (`tmmi.db`)。通过 `StreamProvider.watch()` 实现响应式更新。

## 路由表 (GoRouter)

| 路径 | 页面 | 导航方式 |
|------|------|----------|
| `/` | `ScaffoldWithNavBar` (4 标签) | Shell route |
| `/add-transaction` | `AddTransactionScreen` | Push (extra: type 或 transaction) |
| `/voice-input` | `VoiceInputScreen` | Push |
| `/detail/:id` | `BillDetailScreen` | Push (路径参数: id) |
| `/categories` | `CategoryManagementScreen` | Push |
| `/categories/add` | `CategoryFormScreen` | Push |
| `/categories/edit/:id` | `CategoryFormScreen` | Push (路径参数: id) |
| `/search` | `SearchScreen` | Push |
| `/settings` | `SettingsScreen` | Push |
| `/budget` | `BudgetScreen` | Push |
| `/export` | `DataExportScreen` | Push |
| `/about` | `AboutScreen` | Push |

标签索引由 `currentTabIndexProvider` (`StateProvider<int>`) 管理: 0=首页, 1=账单, 2=统计, 3=我的。语言切换通过 `localeRefreshProvider` 触发 GoRouter 页面重建, 而不重建路由器实例。

## 目录结构

```
lib/
  core/            — 路由、主题、常量
  providers/       — Riverpod providers (database, UI, debug)
  data/database/   — drift 表定义、DAO、app_database.dart
  data/models/     — 数据模型 (当前为空)
  services/        — ASR、语义解析、支出解析
  ui/              — 按功能划分的页面
    shared/widgets/ — 可复用的玻璃拟态组件
    home/, bills/, statistics/, profile/, settings/,
    budget/, categories/, detail/, search/, export/,
    voice_input/, add_transaction/, about/, debug/
  l10n/            — ARB 文件 + 生成的本地化代码
```

## 状态管理 (Riverpod)

使用的 Provider 类型:

| 类型 | 用途 |
|------|------|
| `Provider` | 单例注入 (database, DAOs, router) |
| `StreamProvider` | 响应式数据库查询 (交易、分类、统计) |
| `StateProvider` | 简单可变状态 (currentMonth, tabIndex, 搜索词) |
| `NotifierProvider` | 带逻辑的状态 (LocaleNotifier, ThemeModeNotifier) |
| `FutureProvider` | 一次性异步 (引擎选择、预算数据) |
| `.autoDispose` | 流/Future provider 自动清理 |
| `.family` | 参数化 (transactionsByMonthProvider.family, categoryRankingProvider.family) |

关键 UI providers:

- `currentMonthProvider` (StateProvider<DateTime>) — 统计页选中的月份
- `currentTabIndexProvider` (StateProvider<int>) — 当前底部标签
- `localeProvider` (NotifierProvider) — 语言设置, 持久化到数据库
- `themeModeProvider` (NotifierProvider) — dark/light/system, 持久化到数据库
- `currentAsrEngineProvider` (FutureProvider) — 动态 ASR 引擎
- `currentSemanticParserProvider` (FutureProvider) — 动态语义解析引擎

## 国际化 (l10n)

- ARB 文件: `lib/l10n/intl_en.arb`, `lib/l10n/intl_zh.arb`
- 生成代码: `app_localizations.dart` (类 `AppLocalizations`)
- 语言选择存储在数据库 key `language`
- 语言切换触发 `localeRefreshProvider` 强制 GoRouter 页面重建

## 关键文件

| 文件 | 用途 |
|------|------|
| `lib/main.dart` | 入口 |
| `lib/app.dart` | `TimiApp` (ProviderScope + MaterialApp.router) |
| `lib/core/router/app_router.dart` | GoRouter 配置 + 全部路由 |
| `lib/core/theme/app_theme.dart` | `AppTheme` 类 (颜色、装饰、主题) |
| `lib/providers/database_provider.dart` | DAO 注入 |
| `lib/providers/ui_providers.dart` | 业务状态 Provider |
| `lib/data/database/app_database.dart` | `AppDatabase` (drift) + 迁移 + 初始数据 |
| `pubspec.yaml` | 依赖、资源、版本 |
