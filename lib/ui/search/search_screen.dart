// 搜索页面
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/ui/shared/icon_helpers.dart';

// ========== 工具函数 ==========

/// 格式化日期为显示标签（今天 / 昨天 / MM/dd）
String _formatDateLabel(DateTime date, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(date.year, date.month, date.day);
  if (dateDay == today) {
    return l10n.today;
  } else if (dateDay == today.subtract(const Duration(days: 1))) {
    return l10n.yesterday;
  } else {
    return DateFormat('MM/dd').format(date);
  }
}

// ========== 筛选选项模型 ==========

/// 筛选选项，将显示标签与内部值分离以实现 i18n
class _FilterOption {
  final String value;
  final String label;
  const _FilterOption(this.value, this.label);
}

// ========== 搜索页面 ==========

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _keyword = '';
  String _activeFilterValue = 'all';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 搜索输入防抖（300ms 后触发搜索）
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _keyword = value);
    });
  }

  /// 切换筛选分类（立即触发搜索）
  void _onFilterChanged(String filterValue) {
    _debounceTimer?.cancel();
    setState(() => _activeFilterValue = filterValue);
  }

  /// 清除搜索内容
  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() => _keyword = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 监听全部分类，动态生成筛选栏选项和分类映射表
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final catMap = {for (final c in categories) c.id: c};
    // 筛选栏选项
    final filterOptions = <_FilterOption>[
      _FilterOption('all', l10n.all),
      _FilterOption('expense', l10n.expenseLabel),
      _FilterOption('income', l10n.incomeLabel),
      ...categories.map((c) => _FilterOption('cat_${c.id}', c.name)),
    ];

    // 当前是否有活跃搜索条件
    final hasActiveSearch = _keyword.isNotEmpty || _activeFilterValue != 'all';

    // 解析当前筛选参数传给 DAO
    String? searchType;
    int? searchCategoryId;
    if (_activeFilterValue == 'expense') {
      searchType = 'expense';
    } else if (_activeFilterValue == 'income') {
      searchType = 'income';
    } else if (_activeFilterValue.startsWith('cat_')) {
      final id = int.tryParse(_activeFilterValue.substring(4));
      if (id != null) searchCategoryId = id;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            _buildSearchInput(context, l10n),
            const SizedBox(height: 12),
            _buildFilterBar(context, filterOptions),
            const SizedBox(height: 12),
            Expanded(
              child: hasActiveSearch
                  ? _buildSearchResults(
                      keyword: _keyword,
                      type: searchType,
                      categoryId: searchCategoryId,
                      catMap: catMap,
                      l10n: l10n,
                    )
                  : _buildEmptyState(l10n.searchIdle, context),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建搜索结果区域（使用 StreamBuilder 实时响应数据库变化）
  Widget _buildSearchResults({
    required String keyword,
    required String? type,
    required int? categoryId,
    required Map<int, CategoriesTableData> catMap,
    required AppLocalizations l10n,
  }) {
    final dao = ref.read(transactionDaoProvider);
    final searchStream = dao.search(keyword, type: type, categoryId: categoryId);

    return StreamBuilder<List<TransactionsTableData>>(
      stream: searchStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildEmptyState(l10n.searchLoading, context);
        }
        if (snapshot.hasError) {
          return _buildEmptyState(l10n.searchError, context);
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return _buildEmptyState(l10n.noResults, context);
        }

        // 按日期分组
        final grouped = <String, List<TransactionsTableData>>{};
        for (final r in results) {
          final label = _formatDateLabel(r.date, l10n);
          grouped.putIfAbsent(label, () => []).add(r);
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: grouped.entries.map((entry) {
            return _DateGroupSection(
              dateLabel: entry.key,
              results: entry.value,
              categoryMap: catMap,
            );
          }).toList(),
        );
      },
    );
  }

  /// 构建空状态提示
  Widget _buildEmptyState(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsLight.magnifyingGlass,
            size: 64,
            color: AppTheme.glassFill(context),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部标题栏（返回按钮 + 标题）
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Icon(
                PhosphorIconsLight.arrowLeft,
                color: AppTheme.textOnSurface(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.search,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textOnSurface(context),
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  /// 构建搜索输入框（毛玻璃风格）
  Widget _buildSearchInput(BuildContext context, AppLocalizations l10n) {
    final hasText = _searchController.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: 16, right: 16),
        decoration: BoxDecoration(
          color: AppTheme.glassFill(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.glassStroke(context)),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsLight.magnifyingGlass,
              size: 20,
              color: AppTheme.textOnSurfaceTertiary(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: AppTheme.textOnSurface(context),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: l10n.searchHint,
                  hintStyle: TextStyle(
                    color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            if (hasText)
              GestureDetector(
                onTap: _clearSearch,
                child: Icon(
                  PhosphorIconsLight.xCircle,
                  size: 18,
                  color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建筛选栏（横向滚动）
  Widget _buildFilterBar(BuildContext context, List<_FilterOption> filterOptions) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filterOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = filterOptions[index];
          final isActive = _activeFilterValue == option.value;
          return GestureDetector(
            onTap: () => _onFilterChanged(option.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.glassFillAccent(context)
                    : AppTheme.glassFillStrong(context),
                borderRadius: BorderRadius.circular(15),
                border: isActive
                    ? null
                    : Border.all(color: AppTheme.glassStroke(context)),
              ),
              alignment: Alignment.center,
              child: Text(
                option.label,
                style: TextStyle(
                  color: isActive
                      ? AppTheme.textOnSurface(context)
                      : AppTheme.textOnSurface(context).withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ========== 日期分组区块 ==========

/// 按日期分组的搜索结果区块
class _DateGroupSection extends StatelessWidget {
  final String dateLabel;
  final List<TransactionsTableData> results;
  final Map<int, CategoriesTableData> categoryMap;

  const _DateGroupSection({
    required this.dateLabel,
    required this.results,
    required this.categoryMap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textOnSurfaceSecondary(context),
            ),
          ),
        ),
        ...results.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SearchResultItem(
              transaction: r,
              category: categoryMap[r.categoryId],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ========== 单条搜索结果行 ==========

/// 单条搜索结果行
class _SearchResultItem extends StatelessWidget {
  final TransactionsTableData transaction;
  final CategoriesTableData? category;

  const _SearchResultItem({
    required this.transaction,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isExpense = transaction.type == 'expense';
    final amountColor = isExpense
        ? const Color(0xFFF87171)
        : AppTheme.accentGreen;
    final sign = isExpense ? '-' : '+';
    final iconData = category != null
        ? resolveCategoryIcon(category!.icon)
        : PhosphorIconsLight.placeholder;
    final iconColor = category != null
        ? parseHexColor(category!.color)
        : AppTheme.glassFill(context);
    final catName = category?.name ?? l10n.uncategorized;
    final note = transaction.note ?? '';

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.glassFillStrong(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(iconData, color: iconColor, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catName,
                  style: TextStyle(
                    color: AppTheme.textOnSurface(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  note,
                  style: TextStyle(
                    color: AppTheme.textOnSurface(context).withValues(alpha: 0.54),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$sign¥${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: amountColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
