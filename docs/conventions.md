# 代码规范与测试

## 代码规范

- **导入**: 只用 `package:timi/`, 不用相对路径 `../../`
- **注释**: 中文, 行内注释 (不写在行尾)
- **命名**:
  - drift DataClass: `<TableName>TableData`
  - Phosphor 图标: `PhosphorIconsLight.xxx`, `PhosphorIconsFill.xxx`
  - 私有组件: `_CamelCase` (下划线前缀)
  - Provider 函数: camelCase + `Provider` 后缀
- **页面模式**:
  - 无状态 → `ConsumerWidget` + `WidgetRef ref`
  - 有状态 → `ConsumerStatefulWidget` + `ConsumerState`
  - 子组件作为同文件私有类 (`_Header`, `_Content` 等)
  - `AnnotatedRegion<SystemUiOverlayStyle>` 控制状态栏样式
  - `SafeArea` 处理边距, `ListView` 承载滚动内容
- **错误处理**:
  - AI 服务调用: try-catch → `debugPrint` → 降级逻辑
  - 面向用户的错误: `TopNotification.show(context, message: ..., type: TopNotificationType.error)`
  - DAO 操作: drift 异常直接抛出, 不做笼统捕获
- **禁用 `StateNotifier`** — 使用现代 `Notifier<State>`
- **Flutter 开发规范**另有 `.opencode/rules/Flutter开发规范.md`, 工作流约定见 `.opencode/rules/工作流铁律.md`

## 测试与 QA

- 框架: `flutter_test`
- 测试位置: `test/services/`, `test/widget_test.dart`
- 现有测试:
  - `expense_parser_test.dart` — 28 个 (金额提取、分类匹配、备注提取)
  - `dashscope_asr_service_test.dart` — 9 个 (从 JSON 响应提取转写文本)
  - `widget_test.dart` — 1 个冒烟测试 (Flutter 默认计数器, 未反映真实应用)
- drift 表变更后: 运行 `build_runner build` 重新生成 `.g.dart`
- Lint: `package:flutter_lints/flutter.yaml` (默认规则, 无自定义覆盖)

## 常量

| 文件 | 内容 |
|------|------|
| `transaction_type.dart` | `TransactionType` 枚举 (expense/income) |
| `filter_type.dart` | `FilterType` 枚举 (all/expense/income) + categoryPrefix |
| `settings_keys.dart` | 数据库键字符串、引擎类型常量、主题模式值 |
| `preset_categories.dart` | 12 支出 + 6 收入预设分类 (含图标/颜色映射) |

## 运行环境与工具

- Dart SDK: `^3.11.5`
- drift 代码生成需要 build_runner
- SQLite 通过 `sqlite3_flutter_libs` (部分平台使用系统 SQLite)
- 资源: `assets/icon/icon.png`, `assets/launch_image.png`, `assets/avatar.png`
- 启动图: `flutter_native_splash` 配置
- 应用图标: `flutter_launcher_icons` 生成
- Windows PowerShell 不支持 `&&` — 用 `; if ($?) { }` 链接命令
- 文件写入用 UTF-8 (避免 PowerShell UTF-16LE)
