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

/// 标签页配置
class _TabConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabConfig(this.icon, this.activeIcon, this.label);
}

/// 平板布局最小宽度阈值（Material Design medium 断点）
const double _tabletBreakpoint = 600;

/// 响应式导航框架（手机底部悬浮导航 / 平板左侧导航栏）
///
/// 根据屏幕宽度自动切换布局：
/// - 宽度 < 600dp：当前底部悬浮药丸导航
/// - 宽度 >= 600dp：左侧 NavigationRail 导航（平板/大屏适配）
///
/// 使用 IndexedStack + Riverpod 管理标签切换。
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({super.key});

  // 四个标签页配置
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tabs = _tabs(l10n);
    final currentIndex = ref.watch(currentTabIndexProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    // 根据屏幕宽度选择布局
    if (screenWidth >= _tabletBreakpoint) {
      return _buildTabletLayout(context, ref, currentIndex, tabs);
    } else {
      return _buildPhoneLayout(context, ref, currentIndex, tabs);
    }
  }

  /// 手机布局：底部悬浮毛玻璃药丸导航
  Widget _buildPhoneLayout(BuildContext context, WidgetRef ref, int currentIndex, List<_TabConfig> tabs) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // 计算悬浮导航的宽度与底部间距
    final double screenWidth = MediaQuery.of(context).size.width;
    final double navWidth = screenWidth > 327 ? 327 : (screenWidth - 32).clamp(0, 327);
    final double navBottom = MediaQuery.of(context).padding.bottom + 16;

    return Scaffold(
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
          Positioned(
            left: 0,
            right: 0,
            bottom: navBottom,
            child: Center(
              child: Container(
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
              ),
            ),
          ),
          // 开发模式：SQL 调试触发按钮和 Sheet
          if (kDebugMode) ...[
            const SqlDebugSheet(),
            const SqlDebugTrigger(),
          ],
        ],
      ),
    );
  }

  /// 平板布局：左侧 NavigationRail + 右侧内容
  Widget _buildTabletLayout(BuildContext context, WidgetRef ref, int currentIndex, List<_TabConfig> tabs) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // 内容区域的左侧内边距，为导航栏留出空间
    final double railWidth = 100;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // 左侧导航栏
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
                // 导航项配置
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
              // 右侧内容区域
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
          // 开发模式：SQL 调试触发按钮和 Sheet
          if (kDebugMode) ...[
            const SqlDebugSheet(),
            const SqlDebugTrigger(),
          ],
        ],
      ),
    );
  }
}
