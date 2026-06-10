# Repository Guidelines

Timi — a Flutter expense tracking app with voice input, AI semantic parsing, budget management, and statistics. Dark glassmorphism design, Chinese-first with English support.

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Dart SDK ^3.11.5) |
| State Management | Riverpod 2.x (Provider/StreamProvider/StateProvider/NotifierProvider/FutureProvider) |
| Routing | GoRouter 15.x (4 tab navigation + 9 push routes) |
| Database | drift ORM 2.x (SQLite, code-gen via build_runner) |
| Icons | phosphor_flutter 2.1.0 |
| Charts | fl_chart 0.70.x |
| Fonts | Google Fonts Inter |
| Animations | flutter_animate |
| ASR | DashScope (WebSocket), Tencent (reserved) |
| AI Parser | DashScope Qwen-turbo (HTTP), rule-based fallback |
| L10n | `flutter_localizations` + intl ARB (en, zh) |

## Architecture & Data Flow

```
main.dart → ProviderScope → TimiApp (ConsumerWidget)
  ├── MaterialApp.router (GoRouter)
  │     ├── /  → ScaffoldWithNavBar (IndexedStack + currentTabIndexProvider)
  │     │     ├── HomeScreen (tab 0)
  │     │     ├── BillsScreen (tab 1)
  │     │     ├── StatisticsScreen (tab 2)
  │     │     └── ProfileScreen (tab 3)
  │     └── push routes (rootNavigatorKey)
  │           ├── /add-transaction, /voice-input, /detail/:id
  │           ├── /categories, /categories/add, /categories/edit/:id
  │           ├── /search, /settings, /budget, /export, /about
  └── BudgetAlertWatcher (overlay notifications)
```

**Data flow**: UI → Riverpod providers → DAOs → drift queries → SQLite (`tmmi.db`). Reactive via `StreamProvider.watch()`.

## Key Directories

```
lib/
  core/            — Router, theme, constants
  providers/       — Riverpod providers (database, UI, debug)
  data/database/   — Drift tables, DAOs, app_database.dart
  data/models/     — Data models (currently empty)
  services/        — ASR, semantic parser, expense parser
  ui/              — Feature-based page screens
    shared/widgets/ — Reusable glassmorphism widgets
    home/, bills/, statistics/, profile/, settings/,
    budget/, categories/, detail/, search/, export/,
    voice_input/, add_transaction/, about/, debug/
  l10n/            — ARB files + generated localizations
```

## Routes (GoRouter)

| Path | Screen | Navigation |
|------|--------|------------|
| `/` | `ScaffoldWithNavBar` (4 tabs) | Shell route |
| `/add-transaction` | `AddTransactionScreen` | Push (extra: type or transaction) |
| `/voice-input` | `VoiceInputScreen` | Push |
| `/detail/:id` | `BillDetailScreen` | Push (path param: id) |
| `/categories` | `CategoryManagementScreen` | Push |
| `/categories/add` | `CategoryFormScreen` | Push |
| `/categories/edit/:id` | `CategoryFormScreen` | Push (path param: id) |
| `/search` | `SearchScreen` | Push |
| `/settings` | `SettingsScreen` | Push |
| `/budget` | `BudgetScreen` | Push |
| `/export` | `DataExportScreen` | Push |
| `/about` | `AboutScreen` | Push |

Tab index managed by `currentTabIndexProvider` (`StateProvider<int>`, 0=Home, 1=Bills, 2=Stats, 3=Profile). Locale changes trigger `localeRefreshProvider` to rebuild GoRouter pages without recreating the router instance.

## Database (drift ORM)

File: `tmmi.db` in app documents directory. Generated via `build_runner`.

### Tables

| Table | Key Columns |
|-------|-------------|
| `CategoriesTable` | id (PK), name, icon, color, type ("expense"/"income"), sortOrder, createdAt, updatedAt |
| `TransactionsTable` | id (PK), amount, categoryId (FK→Categories), type, date, note?, createdAt, updatedAt |
| `BudgetsTable` | id (PK), amount, period, year, month?, createdAt, updatedAt |
| `CategoryBudgetsTable` | id (PK), budgetId (FK→Budgets), categoryId (FK→Categories), amount |
| `SettingsTable` | key (PK), value |

### DAOs

- `TransactionDao` — CRUD + watchByMonth, watchByType, search, watchMonthlySummary, watchDailyTotals, watchCategoryRanking, watchYearlyMonthlyTotals, getByDateRange, getMonthlyTotalByType
- `CategoryDao` — CRUD + watchAll, watchByType, updateSortOrder
- `BudgetDao` — getMonthly, upsertMonthlyBudget, upsertCategoryBudget, getCategoryBudgets, setCategoryBudget
- `SettingsDao` — get, set (upsert key-value)

### Naming

- Drift DataClass: `<TableName>TableData` (e.g. `TransactionsTableData`, `CategoriesTableData`)
- DAO methods: `get*` (one-shot), `watch*` (stream), `insert`/`update`/`delete`
- Insert/update use `*TableCompanion` objects with `Value(...)` wrapping

## Services

### ASR (Speech Recognition)
- Abstract: `AsrService` — connect, sendAudio, transcriptStream, stop, disconnect, isConnected, connectionStateStream
- Implementation: `DashScopeAsrService` (WebSocket → paraformer-realtime-v2)
- Reserved: Tencent ASR

### Semantic Parsing (AI → Structured Data)
- Abstract: `SemanticParserService` — parse(text, apiKey, today?) → ParsedExpense
- Implementation: `DashScopeSemanticParser` (HTTP → qwen-turbo)
- `ParsedExpense` fields: amount?, categoryName?, type?, date?, note

### Expense Parsing Pipeline
1. `HybridExpenseParser` — tries AI parser first
2. On failure → falls back to `ExpenseParser` (static regex + keyword rules)
3. `ExpenseParser` uses regex for amounts, keyword map for categories, remainder as note

Engine selection stored in `SettingsTable` keys `asr_engine` and `semantic_parser_engine`.

## Theme (Dark Glassmorphism)

- `AppTheme` static class (lib/core/theme/app_theme.dart)
- Gradient: `#4158D0 → #C850C0 → #FFCC70`
- Dark surface: `#1A1A1A`
- Glass decoration helpers: `glassDecoration()` (no shadow), `glassDecorationFull()` (with shadow)
- Theme-aware colors: `glassFill(context)`, `glassStroke(context)`, `textOnSurface(context)`
- 3 glass fill levels: default, strong, accent
- Semantic colors: accentGreen, accentOrange, accentBlue, accentPurple, accentYellow
- Material 3 enabled, Google Fonts Inter

### Shared Widgets

| Widget | Purpose |
|--------|---------|
| `GlassCard` | Frosted glass container (padding, radius, fill) |
| `GlassHeader` | Title bar with optional back button + actions |
| `GlassButton` | Press-animated frosted glass button |
| `GlassStatusBar` | Static status bar mockup (9:41 + icons) |
| `EmptyState` | Empty placeholder with icon, title, action button |
| `ScaffoldWithNavBar` | Responsive nav: phone bottom pill nav / tablet NavigationRail |
| `TopNotification` | Overlay-based notification banner (replaces SnackBar) |
| `BudgetAlertWatcher` | Wraps app, monitors budget, triggers overlay alert |

### Icon Helpers
- `resolveCategoryIcon(String iconName)` — maps string → PhosphorIconData
- `parseHexColor(String hex)` — `#RRGGBB` → Color
- `categoryIconNames` / `categoryColorHexes` — picker data

## State Management (Riverpod)

Provider types used:

| Type | Usage |
|------|-------|
| `Provider` | Singleton injection (database, DAOs, router) |
| `StreamProvider` | Reactive DB queries (transactions, categories, stats) |
| `StateProvider` | Simple mutable state (currentMonth, tabIndex, search query) |
| `NotifierProvider` | State with logic (LocaleNotifier, ThemeModeNotifier) |
| `FutureProvider` | Async one-shot (engine selection, budget data) |
| `.autoDispose` | Auto-cleanup on stream/future providers |
| `.family` | Parameterized (transactionsByMonthProvider.family, categoryRankingProvider.family) |

Key UI providers:
- `currentMonthProvider` (StateProvider<DateTime>) — selected month for stats
- `currentTabIndexProvider` (StateProvider<int>) — active bottom tab
- `localeProvider` (NotifierProvider) — language setting, persists to DB
- `themeModeProvider` (NotifierProvider) — dark/light/system, persists to DB
- `currentAsrEngineProvider` (FutureProvider) — dynamic ASR engine
- `currentSemanticParserProvider` (FutureProvider) — dynamic semantic parser

## Localization (l10n)

- ARB files: `lib/l10n/intl_en.arb`, `lib/l10n/intl_zh.arb`
- Generated code: `app_localizations.dart` (class `AppLocalizations`)
- Locale selection stored in DB key `language`
- Locale change triggers `localeRefreshProvider` to force GoRouter page rebuild

## Constants

| File | Contents |
|------|----------|
| `transaction_type.dart` | `TransactionType` enum (expense/income) |
| `filter_type.dart` | `FilterType` enum (all/expense/income) + categoryPrefix |
| `settings_keys.dart` | DB key strings, engine type constants, theme mode values |
| `preset_categories.dart` | 12 expense + 6 income default categories with icon/color mappings |

## Development Commands

```bash
flutter analyze                          # Main validation (0 error, 0 warning)
flutter test                             # Run all tests
flutter pub get                          # Install dependencies
flutter pub run build_runner build --delete-conflicting-outputs  # Drift codegen
flutter pub run build_runner watch       # Auto-rebuild on changes
```

Windows PowerShell chaining: `flutter analyze; if ($?) { flutter test }`

## Code Conventions

- **Imports**: `package:timi/` only — no relative `../../` paths
- **Comments**: Chinese, inline (not trailing/end-of-line)
- **Naming**:
  - Drift DataClass: `<TableName>TableData`
  - Phosphor icons: `PhosphorIconsLight.xxx`, `PhosphorIconsFill.xxx`
  - Private widgets: `_CamelCase` (underscore prefix)
  - Provider functions: camelCase with `Provider` suffix
- **Page patterns**:
  - Stateless → `ConsumerWidget` with `WidgetRef ref`
  - Stateful → `ConsumerStatefulWidget` + `ConsumerState`
  - Sub-widgets as private classes in same file (`_Header`, `_Content`, etc.)
  - `AnnotatedRegion<SystemUiOverlayStyle>` for status bar styling
  - `SafeArea` for edge insets, `ListView` for scrollable content
- **Error handling**:
  - AI service calls: try-catch → `debugPrint` → fallback logic
  - User-facing errors: `TopNotification.show(context, message: ..., type: TopNotificationType.error)`
  - DAO operations: drift exceptions propagate, no blanket catches
- **No trailing commas in comments**
- **No `StateNotifier`** — use modern `Notifier<State>` instead

## Testing & QA

- Framework: `flutter_test`
- Test locations: `test/services/`, `test/widget_test.dart`
- Existing tests:
  - `expense_parser_test.dart` — 28 tests (amount extraction, category matching, note extraction)
  - `dashscope_asr_service_test.dart` — 9 tests (transcript extraction from JSON responses)
  - `widget_test.dart` — 1 smoke test (default Flutter counter, not reflecting app)
- After drift changes: run `build_runner build` to regenerate `.g.dart` files
- Lint: `package:flutter_lints/flutter.yaml` (default rules, no custom overrides)

## Runtime/Tooling

- Dart SDK: `^3.11.5`
- Build runner required for drift code generation
- SQLite via `sqlite3_flutter_libs` (system SQLite on some platforms)
- Assets: `assets/icon/icon.png`, `assets/launch_image.png`, `assets/avatar.png`
- Splash screen configured via `flutter_native_splash`
- App icon generation via `flutter_launcher_icons`
- No git, no version control
- Do not use PowerShell `&&` — use `; if ($?) { }` for command chaining
- Write UTF-8 files via `write` tool (avoid PowerShell UTF-16LE)

## Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | Entry point |
| `lib/app.dart` | `TimiApp` widget (ProviderScope + MaterialApp.router) |
| `lib/core/router/app_router.dart` | GoRouter config + all routes |
| `lib/core/theme/app_theme.dart` | `AppTheme` class (colors, decorations, themes) |
| `lib/providers/database_provider.dart` | DAO injection |
| `lib/providers/ui_providers.dart` | Business state providers |
| `lib/data/database/app_database.dart` | `AppDatabase` (drift) + migration + initial data |
| `lib/data/database/daos/transaction_dao.dart` | Transaction queries + statistics |
| `lib/data/database/daos/category_dao.dart` | Category CRUD |
| `lib/data/database/daos/budget_dao.dart` | Budget upsert logic |
| `lib/services/asr_service.dart` | ASR abstraction |
| `lib/services/semantic_parser_service.dart` | Semantic parser abstraction |
| `lib/services/expense_parser.dart` | Rule-based parser |
| `lib/services/dashscope_asr_service.dart` | DashScope ASR implementation |
| `lib/services/dashscope_semantic_parser.dart` | DashScope LLM implementation |
| `lib/ui/shared/widgets/scaffold_with_nav_bar.dart` | Responsive tab navigation |
| `lib/ui/shared/widgets/top_notification.dart` | Overlay notification system |
| `lib/ui/shared/icon_helpers.dart` | Category icon/color mapping |
| `pubspec.yaml` | Dependencies, assets, version |
| `analysis_options.yaml` | Lint config |
| `l10n.yaml` | Localization config |
