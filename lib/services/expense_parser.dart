/// 语音文本解析结果
class ParsedExpense {
  /// 解析出的金额（元），解析失败时为 null
  final double? amount;

  /// 解析出的分类名称，解析失败时为 null
  final String? categoryName;

  /// 交易类型：'expense'（支出）或 'income'（收入），解析失败时为 null
  final String? type;

  /// 交易日期，解析失败时为 null（AI 解析失败时使用当前日期）
  final DateTime? date;

  /// 解析出的备注文本
  final String note;

  const ParsedExpense({
    this.amount,
    this.categoryName,
    this.type,
    this.date,
    this.note = '',
  });

  /// 是否解析出了有效金额
  bool get hasValidAmount => amount != null && amount! > 0;

  /// 获取交易日期，如果解析结果为 null 则返回当前日期
  DateTime get effectiveDate => date ?? DateTime.now();
}

/// 中文语音文本 → 记账数据解析引擎
///
/// 将用户口语化的语音识别文本解析为结构化的记账数据（金额、分类、备注）。
/// 例如："午餐消费 38 元" → amount: 38.0, categoryName: "餐饮", note: "午餐"
class ExpenseParser {
  /// 金额正则：匹配 "X元"、"X块钱"、"X块"、"X毛" 等口语表达
  static final RegExp _amountRegex = RegExp(
    r'(\d+\.?\d*)\s*(元|块钱|块|毛)',
  );

  /// 分类关键词字典：口语关键词 → 分类名称
  ///
  /// 匹配用户在口语中可能提到的分类相关词汇，
  /// 按优先级排序（更具体的词在前）
  static const Map<String, String> _categoryKeywords = {
    // 餐饮类
    '午饭': '餐饮',
    '午餐': '餐饮',
    '早饭': '餐饮',
    '早餐': '餐饮',
    '晚饭': '餐饮',
    '晚餐': '餐饮',
    '吃饭': '餐饮',
    '吃的': '餐饮',
    '外卖': '餐饮',
    '奶茶': '餐饮',
    '咖啡': '餐饮',
    '水': '餐饮',
    '水果': '餐饮',
    '买菜': '餐饮',
    '下馆子': '餐饮',
    '餐厅': '餐饮',
    '食堂': '餐饮',
    '饭': '餐饮',
    '吃': '餐饮',
    '餐': '餐饮',

    // 交通类
    '打车': '交通',
    '出租车': '交通',
    '滴滴': '交通',
    '地铁': '交通',
    '公交': '交通',
    '巴士': '交通',
    '高铁': '交通',
    '火车': '交通',
    '飞机': '交通',
    '机票': '交通',
    '加油': '交通',
    '停车': '交通',
    '车': '交通',

    // 购物类
    '购物': '购物',
    '买东西': '购物',
    '衣服': '购物',
    '裤子': '购物',
    '鞋子': '购物',
    '超市': '购物',
    '淘宝': '购物',
    '京东': '购物',
    '快递': '购物',
    '快递费': '购物',

    // 娱乐类
    '电影': '娱乐',
    '唱歌': '娱乐',
    'KTV': '娱乐',
    '游戏': '娱乐',
    '充值': '娱乐',
    '会员': '娱乐',
    '视频': '娱乐',
    '音乐': '娱乐',
    '门票': '娱乐',

    // 居住类
    '房租': '居住',
    '水电': '居住',
    '电费': '居住',
    '水费': '居住',
    '燃气': '居住',
    '物业': '居住',
    '网费': '居住',
    '宽带': '居住',
    '维修': '居住',

    // 医疗类
    '看病': '医疗',
    '医院': '医疗',
    '药': '医疗',
    '药品': '医疗',
    '买药': '医疗',
    '体检': '医疗',
    '牙科': '医疗',

    // 教育类
    '培训': '教育',
    '课程': '教育',
    '学费': '教育',
    '书': '教育',
    '书本': '教育',
    '文具': '教育',
    '学习': '教育',

    // 通讯类
    '话费': '通讯',
    '手机': '通讯',
    '流量': '通讯',
  };

  /// 解析语音文本为记账数据
  ///
  /// [text] 语音识别返回的中文文本
  /// 返回 [ParsedExpense] 包含金额、分类和备注
  static ParsedExpense parse(String text) {
    if (text.isEmpty) {
      return const ParsedExpense(note: '');
    }
    return _parseSegment(text, _amountRegex.firstMatch(text));
  }

  /// 解析语音文本中可能包含的多笔账目
  ///
  /// 按文本中每个金额出现的位置切分片段，每个片段独立解析。
  /// 例如："午饭25块，打车30块" → [餐饮25, 交通30]。
  /// 无金额或仅一个金额时，行为与 [parse] 一致。
  static List<ParsedExpense> parseAll(String text) {
    if (text.isEmpty) {
      return const [ParsedExpense(note: '')];
    }

    final matches = _amountRegex.allMatches(text).toList();
    if (matches.length <= 1) {
      return [parse(text)];
    }

    final results = <ParsedExpense>[];
    for (var i = 0; i < matches.length; i++) {
      // 每笔账目的文本片段：从前一金额结尾（首笔为文本开头）到当前金额结尾，
      // 这样金额前的描述词（如"午饭25块"的"午饭"）归属当前笔
      final prevEnd = i == 0 ? 0 : matches[i - 1].end;
      final segment = text.substring(prevEnd, matches[i].end).trim();
      results.add(_parseSegment(segment, _amountRegex.firstMatch(segment)));
    }
    return results;
  }

  /// 对多笔账目按同类（分类 + 类型）合并
  ///
  /// 同分类的多笔账目合并为一条：金额相加、备注用分号拼接。
  /// 用于语音输入多笔账目时的自动归类，减少用户确认负担。
  static List<ParsedExpense> mergeSameCategory(List<ParsedExpense> items) {
    if (items.length <= 1) {
      return items;
    }

    // 按 (类型, 分类) 分组，未识别分类的账目单独成组
    final groups = <String, List<ParsedExpense>>{};
    for (final item in items) {
      final key = '${item.type ?? 'expense'}|${item.categoryName ?? ''}';
      groups.putIfAbsent(key, () => []).add(item);
    }

    return groups.values.map((group) {
      if (group.length == 1) {
        return group.first;
      }

      // 金额求和（忽略无有效金额的项）
      double? total;
      final notes = <String>[];
      DateTime? date;
      for (final item in group) {
        if (item.hasValidAmount) {
          total = (total ?? 0) + item.amount!;
        }
        final note = item.note.trim();
        if (note.isNotEmpty) {
          notes.add(note);
        }
        date ??= item.date;
      }

      return ParsedExpense(
        amount: total,
        categoryName: group.first.categoryName,
        type: group.first.type,
        note: notes.join('；'),
        date: date,
      );
    }).toList();
  }

  /// 解析单个文本片段为账目
  ///
  /// [amountMatch] 该片段内首次匹配到的金额，为 null 时金额解析失败。
  static ParsedExpense _parseSegment(String text, RegExpMatch? amountMatch) {
    // 1. 提取金额
    final double? amount;
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!);
    } else {
      amount = null;
    }

    // 2. 从剩余文本中提取分类
    final remainingText = amountMatch != null
        ? text.replaceFirst(_amountRegex, '').trim()
        : text;

    String? categoryName;
    String matchedKeyword = '';

    // 按关键词长度降序匹配（优先匹配更具体的词）
    final sortedKeywords = _categoryKeywords.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sortedKeywords) {
      if (remainingText.contains(entry.key)) {
        categoryName = entry.value;
        matchedKeyword = entry.key;
        break;
      }
    }

    // 3. 提取备注：去除金额原文和匹配到的分类关键词
    String note = text;
    if (amountMatch != null) {
      note = note.replaceFirst(amountMatch.group(0)!, '').trim();
    }
    if (matchedKeyword.isNotEmpty) {
      note = note.replaceAll(matchedKeyword, '').trim();
    }
    // 移除多余的空白
    note = note.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedExpense(
      amount: amount,
      categoryName: categoryName,
      note: note,
    );
  }
}
