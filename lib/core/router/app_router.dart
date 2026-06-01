import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timi/ui/add_transaction/add_transaction_screen.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/ui/voice_input/voice_input_screen.dart';
import 'package:timi/ui/detail/bill_detail_screen.dart';
import 'package:timi/ui/categories/category_form_screen.dart';
import 'package:timi/ui/categories/category_management_screen.dart';
import 'package:timi/ui/search/search_screen.dart';
import 'package:timi/ui/settings/settings_screen.dart';
import 'package:timi/ui/budget/budget_screen.dart';
import 'package:timi/ui/export/data_export_screen.dart';
import 'package:timi/ui/about/about_screen.dart';
import 'package:timi/ui/shared/widgets/scaffold_with_nav_bar.dart';

/// 根导航器 Key，用于 push 路由跳转到全屏页面
/// 根导航器 Key，暴露给外部组件（如 BudgetAlertWatcher）用于访问 Overlay
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// 语言切换刷新信号，用于触发 GoRouter 重建页面（不重新创建路由器实例）
final localeRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  return ValueNotifier(0);
});

/// GoRouter 配置
///
/// 使用 IndexedStack + Riverpod 管理底部标签导航，
/// 标签页路由统一由 '/' 承载，内部通过 currentTabIndexProvider 切换。
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: ref.watch(localeRefreshProvider),
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // 根路由：渲染带底部导航栏的页面框架
      GoRoute(
        path: '/',
        builder: (context, state) => const ScaffoldWithNavBar(),
      ),
      // 以下为全屏 push 路由，使用根导航器
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AddTransactionScreen(
          // 从 extra 中提取参数：{'type': 'income'} 或 {'transaction': ...}
          initialType: (state.extra is Map) ? (state.extra as Map)['type'] as String? : null,
          existingTransaction: (state.extra is Map)
              ? (state.extra as Map)['transaction'] as TransactionsTableData?
              : null,
        ),
      ),
      GoRoute(
        path: '/voice-input',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const VoiceInputScreen(),
      ),
      GoRoute(
        path: '/detail/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => BillDetailScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/categories/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CategoryFormScreen(),
      ),
      GoRoute(
        path: '/categories/edit/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CategoryFormScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/budget',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        path: '/export',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DataExportScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});
