// 数据导出页面 - 按设计规范重构
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDateRangeSection(context),
                      const SizedBox(height: 20),
                      _buildContentTypeSection(context),
                      const SizedBox(height: 20),
                      _buildFormatSection(context),
                      const SizedBox(height: 32),
                      _buildExportButton(context),
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
  Widget _buildHeader(BuildContext context) {
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
            '数据导出',
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
  Widget _buildDateRangeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '时间范围',
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
                  '${_startDate.year}年${_startDate.month}月 - ${_endDate.year}年${_endDate.month}月',
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
  Widget _buildContentTypeSection(BuildContext context) {
    final items = [
      ('all', '所有交易'),
      ('expense', '仅支出'),
      ('income', '仅收入'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '导出内容',
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
  Widget _buildFormatSection(BuildContext context) {
    final formats = ['csv', 'pdf'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '导出格式',
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
  Widget _buildExportButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _showExportSuccess,
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
                '导出并分享',
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

  void _showExportSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('导出成功'),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
