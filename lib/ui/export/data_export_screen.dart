// 数据导出页面 - 按设计规范重构
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  final DateTime _startDate = DateTime(2026, 1, 1);
  final DateTime _endDate = DateTime(2026, 5, 15);
  String _contentType = 'all';
  String _format = 'csv';

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
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              PhosphorIconsLight.arrowLeft,
              size: 24,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const Spacer(),
          Text(
            l10n.dataExport_,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 24),
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
                    _startDate.year.toString(),
                    _startDate.month.toString(),
                    _endDate.year.toString(),
                    _endDate.month.toString(),
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
      ],
    );
  }

  /// "导出内容"分区
  Widget _buildContentTypeSection(BuildContext context, AppLocalizations l10n) {
    final items = [
      ('all', l10n.allTransactions),
      ('expense', l10n.expenseOnly),
      ('income', l10n.incomeOnly),
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
                    color: AppTheme.glassFillStrong(context),
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

  /// "导出格式"分区
  Widget _buildFormatSection(BuildContext context, AppLocalizations l10n) {
    final formats = ['csv', 'pdf'];

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
            child: Column(
              children: List.generate(formats.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.glassFillStrong(context),
                  );
                }
                final i = index ~/ 2;
                final value = formats[i];
                final isSelected = _format == value;
                return _buildRadioItem(
                  label: value.toUpperCase(),
                  isSelected: isSelected,
                  onTap: () => setState(() => _format = value),
                  context: context,
                );
              }),
            ),
          ),
        ),
      ],
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

  /// 导出按钮
  Widget _buildExportButton(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showExportSuccess(l10n),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.glassFillAccent(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppTheme.glassStroke(context),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsLight.downloadSimple,
                size: 22,
                color: AppTheme.textOnSurface(context),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.exportAndShare,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textOnSurface(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportSuccess(AppLocalizations l10n) {
    TopNotification.show(context,
        message: l10n.exportSuccess, type: TopNotificationType.success);
  }
}
