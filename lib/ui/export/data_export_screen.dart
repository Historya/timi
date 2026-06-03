// 数据导出页面 - CSV 导出实现
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timi/core/constants/transaction_type.dart';
import 'package:timi/core/constants/filter_type.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  DateTime _startDate = DateTime(2026, 1, 1);
  DateTime _endDate = DateTime(2026, 5, 15);
  String _contentType = FilterType.all.value;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDateRangeSection(context, l10n),
                      const SizedBox(height: 20),
                      _buildContentTypeSection(context, l10n),
                      const SizedBox(height: 20),
                      _buildFormatSection(context, l10n),
                      const SizedBox(height: 32),
                      _buildExportButton(context, l10n),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              PhosphorIconsLight.arrowLeft,
              size: 24,
              color: AppTheme.textOnSurface(context),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              l10n.dataExport_,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textOnSurface(context),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// "时间范围"分区
  Widget _buildDateRangeSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.dateRange,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: DateTimeRange(
                  start: _startDate,
                  end: _endDate,
                ),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppTheme.accentGreen,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && mounted) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                });
              }
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.glassFillStrong(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.glassStroke(context),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsLight.calendar,
                    size: 22,
                    color: AppTheme.textOnSurface(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.dateRangeFormat(
                      _endDate.month.toString(),
                      _endDate.year.toString(),
                      _startDate.month.toString(),
                      _startDate.year.toString(),
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    PhosphorIconsLight.caretDown,
                    size: 18,
                    color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "导出内容"分区
  Widget _buildContentTypeSection(BuildContext context, AppLocalizations l10n) {
    final items = [
      (FilterType.all.value, l10n.allTransactions),
      (FilterType.expense.value, l10n.expenseOnly),
      (FilterType.income.value, l10n.incomeOnly),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.exportContent,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: AppTheme.glassDecoration(radius: 16, context: context),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: List.generate(items.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.glassFill(context),
                  );
                }
                final i = index ~/ 2;
                final value = items[i].$1;
                final label = items[i].$2;
                final isSelected = _contentType == value;
                return _buildRadioItem(
                  label: label,
                  isSelected: isSelected,
                  onTap: () => setState(() => _contentType = value),
                  context: context,
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  /// "导出格式"分区（仅 CSV，不可切换）
  Widget _buildFormatSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.exportFormat,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: AppTheme.glassDecoration(radius: 16, context: context),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _buildCsvFormatItem(context),
          ),
        ),
      ],
    );
  }

  /// CSV 格式展示项（不可交互，仅提示当前格式）
  Widget _buildCsvFormatItem(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppTheme.accentGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'CSV',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 单选项构建
  Widget _buildRadioItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
                    width: 2,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.textOnSurface(context)
                    : AppTheme.textOnSurface(context).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 导出按钮（导出中显示 loading）
  Widget _buildExportButton(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _isExporting ? null : () => _exportCsv(l10n),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _isExporting
                ? AppTheme.glassFillStrong(context)
                : AppTheme.glassFillAccent(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppTheme.glassStroke(context),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isExporting)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF4ADE80),
                  ),
                )
              else
                Icon(
                  PhosphorIconsLight.downloadSimple,
                  size: 22,
                  color: AppTheme.textOnSurface(context),
                ),
              const SizedBox(width: 8),
              Text(
                _isExporting ? l10n.exporting : l10n.exportAndShare,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isExporting
                      ? AppTheme.textOnSurface(context).withValues(alpha: 0.6)
                      : AppTheme.textOnSurface(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 执行 CSV 导出
  Future<void> _exportCsv(AppLocalizations l10n) async {
    setState(() => _isExporting = true);
    try {
      // 获取数据访问对象
      final transactionDao = ref.read(transactionDaoProvider);
      final categoryDao = ref.read(categoryDaoProvider);

      // 按日期范围查询交易（结束日期 +1 天以包含当天全部记录）
      final endOfDay = _endDate.add(const Duration(days: 1));
      List<TransactionsTableData> transactions;
      if (_contentType == FilterType.all.value) {
        transactions = await transactionDao.getByDateRange(_startDate, endOfDay);
      } else {
        transactions = await transactionDao.getByDateRange(_startDate, endOfDay);
        transactions = transactions.where((t) => t.type == _contentType).toList();
      }

      // 查询全部分类，建立 id → name 映射
      final categories = await categoryDao.getAll();
      final categoryMap = {for (var c in categories) c.id: c.name};

      // 构建 CSV 数据
      final header = ['日期', '类型', '金额', '分类', '备注'];
      final rows = transactions.map((t) => [
        '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
        t.type == TransactionType.expense.value ? '支出' : '收入',
        t.amount.toStringAsFixed(2),
        categoryMap[t.categoryId] ?? '',
        t.note ?? '',
      ]).toList();

      final csvData = [header, ...rows];
      final csvString = const ListToCsvConverter().convert(csvData);

      // 写入文件
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/timi_export_$timestamp.csv');
      await file.writeAsString(csvString);

      // 分享文件
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Timi ${l10n.dataExport}',
      );

      if (mounted) {
        TopNotification.show(context,
            message: l10n.exportSuccess, type: TopNotificationType.success);
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(context,
            message: '$e', type: TopNotificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
