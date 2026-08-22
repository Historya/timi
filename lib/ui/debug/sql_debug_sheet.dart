import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/providers/debug_providers.dart';

/// SQL 调试面板 - 从右侧滑出的 Sheet
///
/// 用于在开发环境下执行原生 SQL 并查看结果。
/// 仅通过 [SqlDebugTrigger] 按钮触发，在 debug 模式下可用。
class SqlDebugSheet extends ConsumerStatefulWidget {
  const SqlDebugSheet({super.key});

  @override
  ConsumerState<SqlDebugSheet> createState() => _SqlDebugSheetState();
}

class _SqlDebugSheetState extends ConsumerState<SqlDebugSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  final ScrollController _resultScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 滑入/滑出动画控制器
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _resultScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(sqlDebugOpenProvider);

    // 监听展开/收起状态变化，触发动画
    if (isOpen) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }

    // 不显示时返回空组件（但保留动画状态）
    if (!isOpen && !_slideController.isAnimating) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    // Sheet 宽度：小屏取 85%，大屏取 480px
    final sheetWidth = min(screenWidth * 0.85, 480.0);

    return SlideTransition(
      position: _slideAnimation,
      child: SafeArea(
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: sheetWidth,
            height: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: _SheetContent(
                resultScrollController: _resultScrollController,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet 内部内容（提取为单独组件以便优化重建范围）
class _SheetContent extends ConsumerWidget {
  final ScrollController resultScrollController;

  const _SheetContent({required this.resultScrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sqlInput = ref.watch(sqlInputProvider);
    final isExecuting = ref.watch(sqlExecutingProvider);
    final queryResult = ref.watch(sqlQueryResultProvider);
    final affectedRows = ref.watch(sqlAffectedRowsProvider);
    final error = ref.watch(sqlErrorProvider);
    final execTimeMs = ref.watch(sqlExecTimeMsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceDark.withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.97),
        border: Border(
          left: BorderSide(color: AppTheme.glassStroke(context), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.glassShadowColor(context),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- 标题栏 ---
          _buildHeader(context, ref, isDark),

          // --- SQL 输入区 ---
          _buildSqlInput(context, ref, sqlInput, isExecuting, isDark),

          // --- 执行按钮 ---
          _buildExecuteButton(context, ref, isExecuting),

          // --- 执行信息（耗时） ---
          if (execTimeMs != null) _buildExecInfo(context, execTimeMs, isDark),

          // --- 错误信息 ---
          if (error != null) _buildError(error, isDark),

          // --- 结果区 ---
          if (queryResult != null)
            Expanded(child: _buildResultTable(context, queryResult, isDark))
          else if (affectedRows != null)
            _buildAffectedRows(affectedRows, isDark),
        ],
      ),
    );
  }

  /// 标题栏：标题 + 清除按钮 + 关闭按钮
  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.glassStroke(context), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsLight.database,
            size: 18,
            color: AppTheme.textOnSurfaceSecondary(context),
          ),
          const SizedBox(width: 8),
          Text(
            'SQL Debug',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const Spacer(),
          // 清除结果按钮
          IconButton(
            icon: Icon(
              PhosphorIconsLight.trash,
              size: 16,
              color: AppTheme.textOnSurfaceTertiary(context),
            ),
            tooltip: '清除结果',
            onPressed: () => resetSqlResultState(ref),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 4),
          // 关闭按钮
          IconButton(
            icon: Icon(
              PhosphorIconsLight.x,
              size: 18,
              color: AppTheme.textOnSurfaceSecondary(context),
            ),
            tooltip: '关闭',
            onPressed: () {
              ref.read(sqlDebugOpenProvider.notifier).state = false;
            },
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// SQL 输入框
  Widget _buildSqlInput(
    BuildContext context,
    WidgetRef ref,
    String sqlInput,
    bool isExecuting,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: TextEditingController(text: sqlInput)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: sqlInput.length),
          ),
        onChanged: (val) {
          ref.read(sqlInputProvider.notifier).state = val;
        },
        enabled: !isExecuting,
        maxLines: 4,
        minLines: 2,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: AppTheme.textOnSurface(context),
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText:
              '输入 SQL 语句...\n例如: SELECT * FROM transactions_table LIMIT 10',
          hintStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppTheme.textOnSurfaceTertiary(context),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.08),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.glassStroke(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.glassStroke(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppTheme.accentBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  /// 执行按钮
  Widget _buildExecuteButton(
    BuildContext context,
    WidgetRef ref,
    bool isExecuting,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: FilledButton.icon(
          onPressed: isExecuting ? null : () => _executeSql(context, ref),
          icon: isExecuting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(PhosphorIconsLight.play, size: 16),
          label: Text(isExecuting ? '执行中...' : '执行 (Ctrl+Enter)'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 执行 SQL 语句
  Future<void> _executeSql(BuildContext context, WidgetRef ref) async {
    final sql = ref.read(sqlInputProvider).trim();
    if (sql.isEmpty) return;

    // 重置之前的结果
    resetSqlResultState(ref);
    ref.read(sqlExecutingProvider.notifier).state = true;

    try {
      final db = ref.read(databaseProvider);
      final stopwatch = Stopwatch()..start();

      // 判断是否为 SELECT 查询
      final isSelect = sql.trim().toUpperCase().startsWith('SELECT');

      if (isSelect) {
        // SELECT 语句：使用 customSelect 获取查询结果
        final result = await db.customSelect(sql).get();
        stopwatch.stop();

        final rows = result.map((row) => row.data).toList();
        ref.read(sqlQueryResultProvider.notifier).state = rows;
        ref.read(sqlExecTimeMsProvider.notifier).state =
            stopwatch.elapsedMilliseconds;
      } else {
        // 非 SELECT 语句（INSERT/UPDATE/DELETE 等）
        final count = await db.customUpdate(sql);
        stopwatch.stop();

        ref.read(sqlAffectedRowsProvider.notifier).state = count;
        ref.read(sqlExecTimeMsProvider.notifier).state =
            stopwatch.elapsedMilliseconds;
      }
    } catch (e) {
      ref.read(sqlErrorProvider.notifier).state = e.toString();
    } finally {
      ref.read(sqlExecutingProvider.notifier).state = false;
    }
  }

  /// 执行耗时信息
  Widget _buildExecInfo(BuildContext context, int execTimeMs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(
            PhosphorIconsLight.lightning,
            size: 12,
            color: AppTheme.accentGreen,
          ),
          const SizedBox(width: 4),
          Text(
            '耗时: ${execTimeMs}ms',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textOnSurfaceTertiary(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 错误展示
  Widget _buildError(String error, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIconsLight.warningCircle,
            size: 16,
            color: Colors.red.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.red.shade300,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 受影响行数展示
  Widget _buildAffectedRows(int count, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsLight.checkCircle,
            size: 16,
            color: AppTheme.accentGreen,
          ),
          const SizedBox(width: 8),
          Text(
            '执行成功，影响 $count 行',
            style: TextStyle(fontSize: 13, color: AppTheme.accentGreen),
          ),
        ],
      ),
    );
  }

  /// 查询结果表格
  Widget _buildResultTable(
    BuildContext context,
    List<Map<String, dynamic>> rows,
    bool isDark,
  ) {
    if (rows.isEmpty) {
      return Center(
        child: Text(
          '查询结果为空',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textOnSurfaceTertiary(context),
          ),
        ),
      );
    }

    // 收集所有列名（保持原顺序）
    final columns = <String>[];
    final seen = <String>{};
    for (final row in rows) {
      for (final key in row.keys) {
        if (seen.add(key)) {
          columns.add(key);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 结果行数统计
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Text(
            '返回 ${rows.length} 行, ${columns.length} 列',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textOnSurfaceTertiary(context),
            ),
          ),
        ),
        // 表格
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              controller: resultScrollController,
              child: DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 40,
                columnSpacing: 16,
                horizontalMargin: 12,
                headingRowColor: WidgetStatePropertyAll(
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                ),
                columns: columns
                    .map(
                      (col) => DataColumn(
                        label: Text(
                          col,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textOnSurfaceSecondary(context),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: rows.map((row) {
                  return DataRow(
                    cells: columns.map((col) {
                      final value = row[col];
                      return DataCell(
                        Text(
                          _formatValue(value),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppTheme.textOnSurface(context),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 格式化单元格值
  String _formatValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is double) {
      // 保留两位小数
      return value.toStringAsFixed(2);
    }
    if (value is DateTime) {
      return value.toString();
    }
    return value.toString();
  }
}

/// SQL 调试触发按钮 - 浮动在右下角
///
/// 由父组件通过 `kDebugMode` 控制是否添加到 widget 树。
class SqlDebugTrigger extends ConsumerWidget {
  const SqlDebugTrigger({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(sqlDebugOpenProvider);

    return Positioned(
      right: 0,
      bottom: 120,
      child: GestureDetector(
        onTap: () {
          ref.read(sqlDebugOpenProvider.notifier).state = !isOpen;
        },
        child: Container(
          width: 32,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            border: Border(
              left: BorderSide(
                color: AppTheme.accentBlue.withValues(alpha: 0.3),
                width: 1,
              ),
              top: BorderSide(
                color: AppTheme.accentBlue.withValues(alpha: 0.3),
                width: 1,
              ),
              bottom: BorderSide(
                color: AppTheme.accentBlue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Icon(
              isOpen ? PhosphorIconsLight.x : PhosphorIconsLight.database,
              size: 16,
              color: AppTheme.accentBlue,
            ),
          ),
        ),
      ),
    );
  }
}
