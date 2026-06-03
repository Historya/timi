/// 交易类型枚举
///
/// 对应数据库 transactions_table.type 字段，存储值为 "expense"/"income"。
/// 替换项目中所有硬编码的 'expense'/'income' 魔法字符串。
enum TransactionType {
  expense('expense'),
  income('income');

  /// 数据库存储值
  final String value;
  const TransactionType(this.value);

  /// 是否为支出
  bool get isExpense => this == TransactionType.expense;

  /// 是否为收入
  bool get isIncome => this == TransactionType.income;

  /// 从数据库值创建枚举
  static TransactionType fromValue(String value) {
    return TransactionType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TransactionType.expense,
    );
  }
}
