import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/ui/debug/sql_debug_sheet.dart';
import 'package:timi/ui/home/home_screen.dart';
import 'package:timi/ui/bills/bills_screen.dart';
import 'package:timi/ui/statistics/statistics_screen.dart';
import 'package:timi/ui/profile/profile_screen.dart';
import 'package:timi/core/router/route_observer.dart';

/// 标签页配置
class _TabConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabConfig(this.icon, this.activeIcon, this.label);
}

/// 平板布局最小宽度阈值（Material Design medium 断点）
const double _tabletBreakpoint = 600;

/// 响应式框架导航（手机底部悬浮导航 / 平板左侧导航栏）
///
/// 根据屏幕宽度自动切换布局：
/// - 宽度 < 600dp：当前底部悬浮药丸导航（页面上滑时自动隐藏导航）
/// - 宽度 >= 600dp：左侧 NavigationRail 导航（平板/大屏适配）
///
/// 使用 IndexedStack + Riverpod 管理标签切换。
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({super.key});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() =>
      _ScaffoldWithNavBarState();

  static List<_TabConfig> _tabs(AppLocalizations l10n) => [
    _TabConfig(PhosphorIconsLight.house, PhosphorIconsFill.house, l10n.tabHome),
    _TabConfig(PhosphorIconsLight.receipt, PhosphorIconsFill.receipt, l10n.myBills),
    _TabConfig(
      PhosphorIconsLight.chartPieSlice,
      PhosphorIconsFill.chartPieSlice,
      l10n.statistics,
    ),
    _TabConfig(PhosphorIconsLight.user, PhosphorIconsFill.user, l10n.profile),
  ];
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar>
    with SingleTickerProviderStateMixin, RouteAware {
  late final AnimationController _navController;
  double _accumulatedDelta = 0;
  static const double _scrollThreshold = 16;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _navController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // 从其他页面返回，重置底部导航为显示状态
    _navController.forward();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    double scrollDelta = 0;
    if (notification is ScrollUpdateNotification) {
      scrollDelta = notification.scrollDelta ?? 0;
    } else if (notification is OverscrollNotification) {
      scrollDelta = notification.overscroll;
    }
    if (scrollDelta != 0) {
      _accumulatedDelta += scrollDelta;
      if (_accumulatedDelta.abs() >= _scrollThreshold) {
        if (_accumulatedDelta > 0) {
          _navController.reverse();
        } else {
          _navController.forward();
        }
        _accumulatedDelta = 0;
      }
    } else if (notification is ScrollEndNotification ||
        notification is UserScrollNotification) {
      _accumulatedDelta = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = ScaffoldWithNavBar._tabs(l10n);
    final currentIndex = ref.watch(currentTabIndexProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= _tabletBreakpoint) {
      return _buildTabletLayout(context, ref, currentIndex, tabs);
    }
    return _buildPhoneLayout(context, ref, currentIndex, tabs);
  }

  Widget _buildPhoneLayout(BuildContext context, WidgetRef ref,
      int currentIndex, List<_TabConfig> tabs) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double navWidth =
        screenWidth > 327 ? 327 : (screenWidth - 32).clamp(0, 327);
    final double navBottom = MediaQuery.of(context).padding.bottom + 16;

    final Widget navBar = Container(
      width: navWidth,
      height: 62,
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.glassFillStrong(context)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(31),
        border: Border.all(
          color: isDark
              ? AppTheme.glassStroke(context)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.glassShadowColor(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final isActive = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(currentTabIndexProvider.notifier).state = i,
              child: Container(
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.glassFillNavBar(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? tab.activeIcon : tab.icon,
                      size: 24,
                      color: isActive
                          ? AppTheme.textOnSurface(context)
                          : AppTheme.textOnSurfaceTertiary(context),
                    ),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppTheme.textOnSurface(context)
                            : AppTheme.textOnSurfaceTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );

    final double navHideOffset = 62 + 16;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: currentIndex,
              children: const [
                HomeScreen(),
                BillsScreen(),
                StatisticsScreen(),
                ProfileScreen(),
              ],
            ),
            AnimatedBuilder(
              animation: _navController,
              builder: (context, child) {
                final translateY =
                    (1 - _navController.value) * navHideOffset;
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: navBottom,
                  child: Transform.translate(
                    offset: Offset(0, translateY),
                    child: child,
                  ),
                );
              },
              child: Center(child: navBar),
            ),
            if (kDebugMode) ...[
              const SqlDebugSheet(),
              const SqlDebugTrigger(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, WidgetRef ref,
      int currentIndex, List<_TabConfig> tabs) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double railWidth = 100;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: (i) =>
                    ref.read(currentTabIndexProvider.notifier).state = i,
                labelType: NavigationRailLabelType.all,
                minExtendedWidth: railWidth,
                backgroundColor: Colors.transparent,
                indicatorColor: isDark
                    ? AppTheme.glassFillNavBar(context)
                    : Colors.black.withValues(alpha: 0.08),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 16),
                  child: Icon(
                    PhosphorIconsLight.coin,
                    size: 32,
                    color: AppTheme.textOnSurface(context),
                  ),
                ),
                destinations: tabs.map((tab) {
                  return NavigationRailDestination(
                    icon: Icon(
                      tab.icon,
                      color: AppTheme.textOnSurfaceTertiary(context),
                    ),
                    selectedIcon: Icon(
                      tab.activeIcon,
                      color: AppTheme.textOnSurface(context),
                    ),
                    label: Text(
                      tab.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppTheme.textOnSurfaceSecondary(context),
                      ),
                    ),
                  );
                }).toList(),
              ),
              Expanded(
                child: IndexedStack(
                  index: currentIndex,
                  children: const [
                    HomeScreen(),
                    BillsScreen(),
                    StatisticsScreen(),
                    ProfileScreen(),
                  ],
                ),
              ),
            ],
          ),
          if (kDebugMode) ...[
            const SqlDebugSheet(),
            const SqlDebugTrigger(),
          ],
        ],
      ),
    );
  }
}