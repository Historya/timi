import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timi/services/expense_parser.dart';
import 'package:timi/services/semantic_parser_service.dart';

/// DashScope（通义千问）AI 语义解析引擎实现
///
/// 调用阿里云 DashScope 的通义千问（Qwen-turbo）模型，
/// 将用户语音文本解析为结构化账单数据。
///
/// 与 [DashScopeAsrService] 使用不同的 API Key，
/// 二者应分别配置，相互独立。
class DashScopeSemanticParser implements SemanticParserService {
  @override
  String get engineId => 'dashscope';

  @override
  String get displayName => '阿里云 DashScope（通义千问）';

  /// DashScope 通义千问文本生成 API 地址
  static const String _apiUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';

  /// 使用的 Qwen 模型
  static const String _model = 'qwen-turbo';

  /// 系统提示词：设定 AI 记账助手的角色和行为
  ///
  /// 引导模型提取：金额、交易类型、分类、备注（含时间/地点）、日期。
  /// 支持一次输入多笔账目，返回 JSON 数组。
  static const String _systemPrompt = '''
    你是一个智能记账助手。请从用户的语音识别文本中提取账单信息，并以严格的 JSON 数组格式返回，数组的每一项代表一笔账目。

    每一笔账目必须包含以下字段：
    - amount: 金额（数字，单位：元），必须为正数
    - type: 交易类型（"expense" 表示支出、"income" 表示收入）
    - categoryName: 分类名称（优先使用：餐饮、交通、购物、娱乐、居住、医疗、教育、通讯、工资、红包、转账、日用、美妆、宠物、运动、旅行、数码、礼物、社交、其他）
    - note: 备注说明（简洁的自然语言描述，应包含消费时间、地点等关键信息。例如："中午在海底捞吃饭"、"在星巴克买咖啡"、"下午3点打车去机场"、"15号交房租"）
    - date: 交易日期（格式：YYYY-MM-DD HH:mm:ss，如果文本没有明确日期则使用当天日期）

    要求：
    1. 金额必须为有效正数
    2. 如果文本没有明确说明是收入，默认为 expense
    3. 如果没有明确分类，根据内容推断最合适的分类
    4. note 字段应尽可能包含消费时间和地点，使其读起来像自然的记账备注
    5. 如果语音文本中包含多笔账目，必须逐笔列出，不能遗漏任何一笔
    6. 仅返回 JSON 数组，不要 markdown 代码块，不要额外文字说明
    7. date请返回 完整的时间格式（YYYY-MM-DD HH:mm:ss）,如语义中有时间名词[昨天、前天]请根据参考时间自行计算时间、如果没有明确时间则使用参考时间

    示例：
    用户输入："下午3点在星巴克买了一杯咖啡38元"
    你返回：[{"amount":38,"type":"expense","categoryName":"餐饮","note":"下午在星巴克买咖啡","date":"2026-05-24 13:10:15"}]

    用户输入："收到工资15000块"
    你返回：[{"amount":15000,"type":"income","categoryName":"工资","note":"工资","date":"2026-05-24 16:10:15"}]

    用户输入："15号交房租3000"
    你返回：[{"amount":3000,"type":"expense","categoryName":"居住","note":"交房租","date":"2026-05-15 12:10:15"}]

    用户输入："午饭花了25块，打车去机场花了80块"
    你返回：[{"amount":25,"type":"expense","categoryName":"餐饮","note":"午饭","date":"2026-05-24 12:10:15"},{"amount":80,"type":"expense","categoryName":"交通","note":"打车去机场","date":"2026-05-24"}]
''';

  @override
  Future<List<ParsedExpense>> parse({
    required String text,
    required String apiKey,
    DateTime? today,
  }) async {
    if (text.isEmpty) {
      return const [ParsedExpense(note: '')];
    }

    final referenceDate = today ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(referenceDate);

    // 构造用户消息，注入参考日期
    final userMessage = '语音文本：$text\n参考日期：$dateStr\n请返回 JSON。';

    // 构造 DashScope API 请求体
    final requestBody = jsonEncode({
      'model': _model,
      'input': {
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
      },
      'parameters': {
        'result_format': 'message',
        'temperature': 0.1, // 低温度确保输出稳定
        'max_tokens': 512,
      },
    });

    try {
      // 发送 HTTP POST 请求到 DashScope API
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));

      // 检查 HTTP 状态码
      if (response.statusCode != 200) {
        throw SemanticParseException(
          'API 请求失败 (${response.statusCode}): ${response.body}',
        );
      }

      // 解析响应 JSON
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // 检查 API 返回的错误
      if (responseData.containsKey('code')) {
        throw SemanticParseException(
          'API 错误 (${responseData['code']}): ${responseData['message']}',
        );
      }

      // 提取模型生成的文本内容
      final output = responseData['output'] as Map<String, dynamic>?;
      final choices = output?['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const SemanticParseException('API 返回空结果');
      }

      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const SemanticParseException('模型返回内容为空');
      }

      // 解析模型返回的 JSON 字符串
      return _parseAiResponse(content, referenceDate);
    } catch (e) {
      // 包装所有异常为 SemanticParseException
      if (e is SemanticParseException) rethrow;
      throw SemanticParseException('解析异常: $e');
    }
  }

  /// 解析 AI 模型返回的 JSON 文本（JSON 数组）
  ///
  /// 处理模型可能返回的 markdown 代码块包裹的 JSON。
  /// 兼容模型降级返回单个 JSON 对象的情况（包装为单元素列表）。
  List<ParsedExpense> _parseAiResponse(String content, DateTime referenceDate) {
    // 去除可能的 markdown 代码块标记（```json ... ```）
    String jsonStr = content.trim();
    if (jsonStr.startsWith('```')) {
      // 移除开头的 ```json 或 ``` 以及结尾的 ```
      jsonStr = jsonStr.replaceAll(RegExp(r'^```[a-zA-Z]*\s*'), '');
      jsonStr = jsonStr.replaceAll(RegExp(r'\s*```$'), '');
      jsonStr = jsonStr.trim();
    }

    // 如果字符串被引号包裹，去除引号
    if ((jsonStr.startsWith('"') && jsonStr.endsWith('"')) ||
        (jsonStr.startsWith("'") && jsonStr.endsWith("'"))) {
      jsonStr = jsonStr.substring(1, jsonStr.length - 1);
    }

    // 解析 JSON，兼容数组与单个对象两种返回
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (e) {
      throw SemanticParseException('AI 返回内容无法解析为 JSON: $jsonStr');
    }

    final List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      items = [decoded];
    } else {
      throw SemanticParseException('AI 返回的 JSON 结构不合法: $jsonStr');
    }

    if (items.isEmpty) {
      throw const SemanticParseException('AI 返回的账目列表为空');
    }

    // 逐笔解析
    final results = <ParsedExpense>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        throw const SemanticParseException('AI 返回的账目格式不合法');
      }
      results.add(_parseExpenseItem(item, referenceDate));
    }
    return results;
  }

  /// 解析单笔账目 JSON 对象
  ParsedExpense _parseExpenseItem(
    Map<String, dynamic> data,
    DateTime referenceDate,
  ) {
    // 提取金额
    final double? amount;
    final rawAmount = data['amount'];
    if (rawAmount is num) {
      amount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      amount = double.tryParse(rawAmount);
    } else {
      amount = null;
    }

    // 验证金额有效性
    if (amount == null || amount <= 0) {
      throw SemanticParseException('AI 返回的金额无效: $rawAmount');
    }

    // 提取交易类型
    final type = (data['type'] as String?)?.toLowerCase();
    if (type != null && type != 'expense' && type != 'income') {
      throw SemanticParseException('AI 返回的交易类型无效: $type');
    }

    // 提取分类名称
    final categoryName = data['categoryName'] as String?;
    if (categoryName == null || categoryName.isEmpty) {
      throw SemanticParseException('AI 返回的分类名称为空');
    }

    // 提取备注
    final note = (data['note'] as String?)?.trim() ?? '';

    // 提取日期
    DateTime? date;
    final rawDate = data['date'] as String?;
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        if (rawDate.length == 10) {
          // 仅有日期部分，补充时间为 00:00:00
          date = DateFormat('yyyy-MM-dd ${referenceDate.hour}:${referenceDate.minute}:${referenceDate.second}').parseStrict(rawDate);
        } else {
          date = DateFormat('yyyy-MM-dd HH:mm:ss').parseStrict(rawDate);
        }
      } catch (ignored) {}
    }

    return ParsedExpense(
      amount: amount,
      type: type,
      categoryName: categoryName,
      note: note,
      date: date ?? referenceDate,
    );
  }
}

/// AI 语义解析异常
class SemanticParseException implements Exception {
  final String message;
  const SemanticParseException(this.message);

  @override
  String toString() => 'SemanticParseException: $message';
}
