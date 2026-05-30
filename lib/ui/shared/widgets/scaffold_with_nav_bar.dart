import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/providers/ui_providers.dart';
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

/// 自定义底部导航栏（毛玻璃药丸样式）
///
/// 使用 IndexedStack + Riverpod 管理标签切换，
/// 代替原有的 GoRouter StatefulShellRoute 方案。
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({super.key});

  // 四个标签页配置
  static const _tabs = [
    _TabConfig(PhosphorIconsLight.house, PhosphorIconsFill.house, '首页'),
    _TabConfig(PhosphorIconsLight.receipt, PhosphorIconsFill.receipt, '账单'),
    _TabConfig(
      PhosphorIconsLight.chartPieSlice,
      PhosphorIconsFill.chartPieSlice,
      '统计',
    ),
    _TabConfig(PhosphorIconsLight.user, PhosphorIconsFill.user, '我的'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 Riverpod 读取当前选中的标签索引
    final currentIndex = ref.watch(currentTabIndexProvider);
    // 检测当前是否为暗色模式，用于浅色模式下调整导航栏样式
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // 计算悬浮导航的宽度与底部间距
    final double screenWidth = MediaQuery.of(context).size.width;
    final double navWidth = screenWidth > 327 ? 327 : (screenWidth - 32);
    final double navBottom = MediaQuery.of(context).padding.bottom + 16;

    return Scaffold(
      // 使用 Stack 将悬浮导航叠加在内容之上，保持各标签页状态不丢失
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
                  // 浅色模式使用白色毛玻璃，暗色模式保持原有毛玻璃效果
                  color: isDark
                      ? AppTheme.glassFillStrong(context)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(31),
                  // 浅色模式使用更淡的描边，暗色模式保持原有描边颜色
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
                  children: List.generate(_tabs.length, (i) {
                    final tab = _tabs[i];
                    final isActive = i == currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => ref.read(currentTabIndexProvider.notifier).state = i,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.glassFillNavBar(context) : Colors.transparent,
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
                              const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}
