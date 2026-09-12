# 服务层

## ASR (语音识别)

- **抽象接口**: `AsrService` — connect, sendAudio, transcriptStream, stop, disconnect, isConnected, connectionStateStream
- **实现**:
  - `DashScopeAsrService` — WebSocket → paraformer-realtime-v2
  - `TencentAsrService` — 腾讯云 ASR
  - `OfflineAsrService` — 离线识别
- 引擎选择存储在 `SettingsTable` key `asr_engine`

## 语义解析 (AI → 结构化数据)

- **抽象接口**: `SemanticParserService` — parse(text, apiKey, today?) → ParsedExpense
- **实现**: `DashScopeSemanticParser` (HTTP → qwen-turbo)
- `ParsedExpense` 字段: amount?, categoryName?, type?, date?, note
- 引擎选择存储在 `SettingsTable` key `semantic_parser_engine`

## 支出解析管线

1. `HybridExpenseParser` — 先尝试 AI 解析
2. 失败时降级 → `ExpenseParser` (静态正则 + 关键词规则)
3. `ExpenseParser` 用正则提取金额, 关键词映射分类, 剩余文本作为备注

## 其他服务

- `KeepAliveService` — Android 前台 Service 保活, 确保应用进程不被系统立即回收

## 相关文件

| 文件 | 用途 |
|------|------|
| `lib/services/asr_service.dart` | ASR 抽象 |
| `lib/services/dashscope_asr_service.dart` | DashScope ASR 实现 |
| `lib/services/tencent_asr_service.dart` | 腾讯云 ASR 实现 |
| `lib/services/offline_asr_service.dart` | 离线 ASR 实现 |
| `lib/services/semantic_parser_service.dart` | 语义解析抽象 |
| `lib/services/dashscope_semantic_parser.dart` | DashScope LLM 实现 |
| `lib/services/expense_parser.dart` | 规则引擎解析器 |
