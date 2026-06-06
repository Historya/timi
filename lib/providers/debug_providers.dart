import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===== SQL 调试 Sheet 状态管理 =====

/// SQL 调试面板的展开/收起状态
final sqlDebugOpenProvider = StateProvider<bool>((ref) => false);

/// SQL 输入框内容
final sqlInputProvider = StateProvider<String>((ref) => '');

/// SQL 执行结果
///
/// - null：尚未执行
/// - []: 空结果（无数据返回）
/// - 非空: 查询结果行
final sqlQueryResultProvider =
    StateProvider<List<Map<String, dynamic>>?>((ref) => null);

/// 执行影响的记录数（仅 UPDATE/DELETE/INSERT 等 DML 语句）
final sqlAffectedRowsProvider = StateProvider<int?>((ref) => null);

/// 错误信息
final sqlErrorProvider = StateProvider<String?>((ref) => null);

/// 是否正在执行
final sqlExecutingProvider = StateProvider<bool>((ref) => false);

/// 执行耗时（毫秒）
final sqlExecTimeMsProvider = StateProvider<int?>((ref) => null);

/// 重置所有结果状态
void resetSqlResultState(WidgetRef ref) {
  ref.read(sqlQueryResultProvider.notifier).state = null;
  ref.read(sqlAffectedRowsProvider.notifier).state = null;
  ref.read(sqlErrorProvider.notifier).state = null;
  ref.read(sqlExecutingProvider.notifier).state = false;
  ref.read(sqlExecTimeMsProvider.notifier).state = null;
}
