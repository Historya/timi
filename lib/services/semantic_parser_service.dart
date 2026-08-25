import 'package:timi/services/expense_parser.dart';

/// AI 语义解析引擎抽象接口
///
/// 所有 AI 语义解析引擎必须实现此接口。
/// 目前实现：[DashScopeSemanticParser]（阿里云通义千问）
///
/// 设计意图：与 ASR 引擎（[AsrService]）采用相同策略模式，
/// 仅有一个 parse() 核心方法，方便后续增加不同 LLM 提供商。
abstract class SemanticParserService {
  /// 引擎唯一标识（用于 SettingsTable 存储和配置）
  String get engineId;

  /// 引擎显示名称（用于设置页面展示）
  String get displayName;

  /// 解析语音文本为结构化记账数据
  ///
  /// [text] 语音识别返回的中文文本
  /// [apiKey] 调用 LLM 所需的 API Key
  /// [today] 参考日期，用于日期推理
  /// 返回 [ParsedExpense] 结构化解析结果列表。
  /// 当语音文本包含多笔账目时返回多条（如"午饭25块，打车30块"）。
  Future<List<ParsedExpense>> parse({
    required String text,
    required String apiKey,
    DateTime? today,
  });
}
