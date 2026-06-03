/// 导出/搜索页面的筛选类型枚举
///
/// 替换项目中硬编码的 'all'/'expense'/'income' 筛选魔法字符串。
enum FilterType {
  all('all'),
  expense('expense'),
  income('income');

  /// 筛选值标识
  final String value;
  const FilterType(this.value);

  /// 是否为"全部"筛选
  bool get isAll => this == FilterType.all;

  /// 是否为"支出"筛选
  bool get isExpense => this == FilterType.expense;

  /// 是否为"收入"筛选
  bool get isIncome => this == FilterType.income;

  /// 分类筛选前缀（用于搜索页分类筛选，如 "cat_3"）
  static const String categoryPrefix = 'cat_';

  /// 从字符串值创建
  static FilterType fromValue(String value) {
    return FilterType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => FilterType.all,
    );
  }
}
