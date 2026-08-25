import 'package:flutter/foundation.dart';

import 'package:timi/services/expense_parser.dart';
import 'package:timi/services/semantic_parser_service.dart';

/// AI 解析器与规则引擎的组合解析器
///
/// 策略模式：优先调用 [SemanticParserService]（AI 大模型），
/// 如果 AI 解析失败（网络异常、API 错误、返回格式不合法），
/// 自动降级到 [ExpenseParser]（正则规则引擎）。
///
/// 使用方式：
/// ```dart
/// final service = await ref.read(currentSemanticParserProvider.future);
/// final parser = HybridExpenseParser(service: service, apiKey: apiKey);
/// final result = await parser.parse(text: '中午吃饭花了38块钱');
/// ```
class HybridExpenseParser {
  /// AI 语义解析引擎实例，为 null 时直接降级到规则引擎
  final SemanticParserService? _service;

  /// LLM API Key，为空时跳过 AI 解析
  final String? _apiKey;

  /// 构造组合解析器
  ///
  /// [service] AI 语义解析引擎实例（来自 provider）
  /// [apiKey] LLM API Key，为空或 null 时跳过 AI 直接使用规则引擎
  HybridExpenseParser({
    SemanticParserService? service,
    String? apiKey,
  })  : _service = service,
        _apiKey = apiKey;

  /// 组合解析语音文本
  ///
  /// [text] 语音识别返回的中文文本
  /// [today] 参考日期
  /// 返回 [ParsedExpense] 结构化解析结果列表，支持多笔账目。
  Future<List<ParsedExpense>> parse({
    required String text,
    DateTime? today,
  }) async {
    if (text.isEmpty) {
      return const [ParsedExpense(note: '')];
    }

    // 优先尝试 AI 语义解析
    final service = _service;
    final apiKey = _apiKey;
    if (service != null && apiKey != null && apiKey.isNotEmpty) {
      try {
        final aiResult = await service.parse(
          text: text,
          apiKey: apiKey,
          today: today,
        );
        return aiResult;
      } catch (e) {
        // AI 解析失败，记录日志并降级到规则引擎
        debugPrint('[HybridParser] AI 解析失败，降级到规则引擎: $e');
      }
    }

    // 降级到规则引擎（支持多笔账目）
    final ruleResults = ExpenseParser.parseAll(text);

    // 补充规则引擎缺失的字段
    final referenceDate = today ?? DateTime.now();
    return ruleResults
        .map(
          (r) => ParsedExpense(
            amount: r.amount,
            categoryName: r.categoryName,
            note: r.note,
            type: 'expense', // 规则引擎默认为支出
            date: r.date ?? referenceDate,
          ),
        )
        .toList();
  }
}
