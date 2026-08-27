# Timi — 极简语音记账

Timi 是一款 Flutter 跨平台记账应用，主打**语音输入**和 **AI 语义解析**，让记账像聊天一样自然。暗色玻璃拟态设计风格，支持中英文国际化。

## 功能特性

- **语音记账** — 按住说话，自动识别并解析为结构化账目（金额、分类、日期、备注）
- **高度隐私**  - 本地储存
- **AI 语义解析** — 接入阿里云通义千问 LLM，自然语言理解账目内容；降级到规则引擎保底
- **智能分类** — 预设 12 个支出分类 + 6 个收入分类，支持自定义
- **预算管理** — 月度总预算 + 按分类分项预算，实时监控超支
- **数据统计** — 月度支出趋势、年度消费趋势、分类排行、每周对比
- **搜索筛选** — 按关键词、分类、日期范围搜索交易记录
- **数据导出** — CSV 格式导出，支持日期范围和类型筛选，分享到其他应用
- **多引擎切换** — 语音识别支持阿里云 DashScope / 腾讯云 ASR 双引擎
- **深色模式** — 跟随系统或手动切换
- **中英文双语** — 完整国际化支持
- **后台保活** — 前台 Service 保持应用响应速度

## 技术栈

| 层次 | 选型 |
|------|------|
| 框架 | Flutter (Dart SDK ^3.11.5) |
| 状态管理 | [Riverpod 2.x](https://riverpod.dev/) (Provider/StreamProvider/NotifierProvider) |
| 路由 | [GoRouter 15.x](https://pub.dev/packages/go_router) (4 标签导航 + 9 push 路由) |
| 数据库 | [drift ORM 2.x](https://drift.simonbinder.eu/) (SQLite, 代码生成) |
| 图标 | [phosphor_flutter](https://pub.dev/packages/phosphor_flutter) 2.1.0 |
| 图表 | [fl_chart](https://pub.dev/packages/fl_chart) 0.70.x |
| 字体 | Google Fonts Inter |
| 动画 | [flutter_animate](https://pub.dev/packages/flutter_animate) |
| 语音识别 | DashScope (WebSocket) / 腾讯云 ASR |
| AI 解析 | DashScope Qwen-turbo (HTTP) / 规则引擎降级 |
| 国际化 | flutter_localizations + intl ARB (en, zh) |

## 架构概览

```
main.dart → ProviderScope → TimiApp (ConsumerWidget)
  ├── MaterialApp.router (GoRouter)
  │     ├── /  → ScaffoldWithNavBar (IndexedStack + 标签页)
  │     │     ├── HomeScreen (tab 0)       — 首页总览
  │     │     ├── BillsScreen (tab 1)      — 账单列表
  │     │     ├── StatisticsScreen (tab 2) — 消费统计
  │     │     └── ProfileScreen (tab 3)    — 个人中心
  │     └── push 路由
  │           ├── /add-transaction          — 添加交易
  │           ├── /voice-input              — 语音记账
  │           ├── /detail/:id              — 账单详情
  │           ├── /categories              — 分类管理
  │           ├── /categories/add          — 新增分类
  │           ├── /categories/edit/:id     — 编辑分类
  │           ├── /search                  — 搜索
  │           ├── /settings                — 设置
  │           ├── /budget                  — 预算管理
  │           ├── /export                  — 数据导出
  │           └── /about                   — 关于
  └── BudgetAlertWatcher (预算超支悬浮通知)
```

**数据流**: UI → Riverpod providers → DAOs → drift 查询 → SQLite (tmmi.db)。通过 `StreamProvider.watch()` 实现响应式更新。

## 项目结构

```
lib/
├── main.dart                        # 入口
├── app.dart                         # TimiApp (ProviderScope + MaterialApp.router)
├── core/
│   ├── router/app_router.dart       # GoRouter 路由配置
│   ├── theme/app_theme.dart         # 暗色玻璃拟态主题
│   └── constants/
│       ├── transaction_type.dart    # TransactionType 枚举
│       ├── filter_type.dart         # FilterType 枚举
│       ├── settings_keys.dart       # 数据库键常量
│       └── preset_categories.dart   # 预设分类数据
├── providers/
│   ├── database_provider.dart       # DAO 注入
│   ├── ui_providers.dart            # 业务状态 Provider
│   └── debug_providers.dart         # 调试工具 Provider
├── data/database/
│   ├── app_database.dart            # AppDatabase (drift) + 迁移 + 初始化
│   ├── app_database.g.dart          # 代码生成
│   ├── tables/                      # 表定义
│   │   ├── categories_table.dart
│   │   ├── transactions_table.dart
│   │   ├── budgets_table.dart
│   │   ├── category_budgets_table.dart
│   │   └── settings_table.dart
│   └── daos/                        # 数据访问对象
│       ├── transaction_dao.dart     # 交易 CRUD + 统计查询
│       ├── category_dao.dart        # 分类 CRUD
│       ├── budget_dao.dart          # 预算管理
│       └── settings_dao.dart        # 设置存取
├── services/
│   ├── asr_service.dart             # 语音识别抽象接口
│   ├── dashscope_asr_service.dart   # DashScope WebSocket 实现
│   ├── offline_asr_service.dart     # 离线 ASR 实现
│   ├── tencent_asr_service.dart     # 腾讯云 ASR 实现
│   ├── semantic_parser_service.dart # AI 语义解析抽象接口
│   ├── dashscope_semantic_parser.dart # DashScope Qwen-turbo 实现
│   ├── semantic_parser.dart         # 语义解析器
│   ├── expense_parser.dart          # 规则引擎降级解析
│   └── keep_alive_service.dart      # 前台 Service 保活
├── ui/
│   ├── home/home_screen.dart        # 首页总览
│   ├── bills/bills_screen.dart      # 账单列表
│   ├── statistics/statistics_screen.dart # 统计图表
│   ├── profile/profile_screen.dart  # 个人中心
│   ├── add_transaction/add_transaction_screen.dart # 添加/编辑交易
│   ├── voice_input/voice_input_screen.dart # 语音输入
│   ├── detail/bill_detail_screen.dart # 账单详情
│   ├── categories/                  # 分类管理
│   ├── budget/budget_screen.dart    # 预算管理
│   ├── search/search_screen.dart    # 搜索
│   ├── settings/settings_screen.dart # 设置
│   ├── export/data_export_screen.dart # 数据导出
│   ├── about/about_screen.dart      # 关于
│   ├── debug/sql_debug_sheet.dart   # SQL 调试面板
│   └── shared/
│       ├── icon_helpers.dart        # 图标/颜色映射
│       └── widgets/                 # 共享组件
│           ├── glass_card.dart      # 毛玻璃卡片
│           ├── glass_button.dart    # 毛玻璃按钮
│           ├── glass_header.dart    # 标题栏
│           ├── glass_status_bar.dart # 状态栏
│           ├── scaffold_with_nav_bar.dart # 导航框架
│           ├── top_notification.dart # 悬浮通知
│           ├── budget_alert_watcher.dart # 预算预警
│           ├── empty_state.dart     # 空状态占位
│           └── keep_alive_starter.dart # 后台保活启动
├── l10n/
│   ├── intl_en.arb                 # 英文翻译
│   └── intl_zh.arb                 # 中文翻译
```

## 数据库 (drift / SQLite)

文件: `tmmi.db` (应用文档目录)

| 表 | 说明 |
|----|------|
| `CategoriesTable` | 分类 (id, name, icon, color, type, sortOrder) |
| `TransactionsTable` | 交易记录 (id, amount, categoryId, type, date, note) |
| `BudgetsTable` | 月度预算 (id, amount, period, year, month) |
| `CategoryBudgetsTable` | 分项预算 (budgetId, categoryId, amount) |
| `SettingsTable` | 键值设置 (key, value) |

## 服务

### ASR (语音识别)

- **抽象**: `AsrService` — connect, sendAudio, transcriptStream, stop, disconnect
- **实现**:
  - `DashScopeAsrService` — WebSocket → paraformer-realtime-v2
  - `TencentAsrService` — 腾讯云 ASR
  - `OfflineAsrService` — 离线识别

### 语义解析 (AI → 结构化数据)

- **抽象**: `SemanticParserService` — parse(text, apiKey, today?) → ParsedExpense
- **实现**: `DashScopeSemanticParser` — HTTP → qwen-turbo
- **降级**: `ExpenseParser` — 正则 + 关键词规则解析

## 主题 (暗色玻璃拟态)

- 渐变背景: `#4158D0 → #C850C0 → #FFCC70`
- 玻璃态装饰: `glassDecoration()` / `glassDecorationFull()`
- 3 级玻璃填充: 默认 / strong / accent
- 语义色板: accentGreen, accentOrange, accentBlue, accentPurple, accentYellow
- 字体: Google Fonts Inter

## 开发指南

### 环境要求

- Flutter SDK (Dart SDK ^3.11.5)
- 平台工具链: Android Studio / Xcode / Visual Studio (Windows)

### 快速开始

```bash
# 获取依赖
flutter pub get

# 生成 drift 代码 (数据库 ORM)
flutter pub run build_runner build --delete-conflicting-outputs

# 运行分析检查
flutter analyze

# 运行测试
flutter test

# 启动应用
flutter run
```

### 开发命令

```bash
flutter analyze                          # 代码分析 (0 error, 0 warning)
flutter test                             # 运行测试
flutter pub get                          # 安装依赖
flutter pub run build_runner build       # drift 代码生成
flutter pub run build_runner watch       # 自动重建
```

## 国际化

- ARB 文件: `lib/l10n/intl_en.arb` / `intl_zh.arb`
- 语言设置存储在 DB key `language`
- 切换语言自动触发页面重建 (localeRefreshProvider)

## 许可

MIT License

Copyright (c) 2024 Timi Team