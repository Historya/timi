import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/providers/ui_providers.dart';

/// 个人资料页面
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听当前月份，传递给统计卡片
    final month = ref.watch(currentMonthProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 根据主题亮度适配状态栏样式
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 页面标题栏
            const _Header(),
            const SizedBox(height: 16),
            // 用户信息行：头像 + 昵称（从数据库读取）
            const _UserInfoRow(),
            const SizedBox(height: 16),
            // 本月统计数据卡片（从数据库读取）
            _StatsCard(month: month),
            const SizedBox(height: 24),
            // 功能设置分区标签
            const _SectionLabel(),
            const SizedBox(height: 8),
            // 菜单功能卡片列表
            _MenuCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// 页面标题栏："我的" 标题 + 设置齿轮按钮
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // "我的" 标题文字
          Text(
            '我的',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          // 设置齿轮按钮跳转到设置页
          IconButton(
            icon: Icon(
              PhosphorIconsLight.gear,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
              size: 22,
            ),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

/// 用户信息行：圆形头像 + 昵称（从数据库加载）与副标题
class _UserInfoRow extends ConsumerWidget {
  const _UserInfoRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 SettingsTable 中读取用户昵称（key: 'nickname'）
    return FutureBuilder<String?>(
      future: ref.read(settingsDaoProvider).get('nickname'),
      builder: (context, snapshot) {
        final nickname = snapshot.data ?? 'Tom';
        return Row(
          children: [
            // 用户头像：80×80 圆形毛玻璃背景，白色用户图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.glassFillAccent(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.glassStroke(context),
                  width: 2,
                ),
              ),
              // child: Icon(
              //   PhosphorIconsLight.user,
              //   color: AppTheme.textOnSurface(context),
              //   size: 44,
              // ),
              child: CircleAvatar(
                radius: 40,
                foregroundImage: AssetImage('assets/avatar.png'),
                child: Icon(
                  PhosphorIconsLight.user,
                  color: AppTheme.textOnSurface(context),
                  size: 44,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 昵称 + 个人资料提示文字
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textOnSurface(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '设置你的个人资料',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textOnSurface(
                      context,
                    ).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 统计数据卡片：本月支出 / 本月收入 / 总交易笔数
class _StatsCard extends ConsumerWidget {
  final DateTime month;

  const _StatsCard({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听指定月份的汇总统计数据
    final statsAsync = ref.watch(monthlyStatsProvider(month));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecorationFull(context: context, radius: 20),
      child: statsAsync.when(
        // 加载成功显示真实数据
        data: (stats) => _buildStatsRow(
          expense:
              '¥${NumberFormat('#,###').format(stats.totalExpense.round())}',
          income: '¥${NumberFormat('#,###').format(stats.totalIncome.round())}',
          count: '${stats.totalCount}笔',
        ),
        // 加载中或出错时显示占位符
        loading: () =>
            _buildStatsRow(expense: '---', income: '---', count: '---'),
        error: (_, _) =>
            _buildStatsRow(expense: '---', income: '---', count: '---'),
      ),
    );
  }

  /// 构建三栏统计数据行
  Widget _buildStatsRow({
    required String expense,
    required String income,
    required String count,
  }) {
    return Row(
      children: [
        _StatItem(value: expense, label: '本月支出'),
        const _VertDivider(),
        _StatItem(value: income, label: '本月收入'),
        const _VertDivider(),
        _StatItem(value: count, label: '总交易'),
      ],
    );
  }
}

/// 垂直分隔线组件
class _VertDivider extends StatelessWidget {
  const _VertDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.textOnSurface(context).withValues(alpha: 0.1),
    );
  }
}

/// 单个统计数据项：数值 + 标签
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // 统计数值
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const SizedBox(height: 6),
          // 统计标签
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.54),
            ),
          ),
        ],
      ),
    );
  }
}

/// 功能设置分区标签
class _SectionLabel extends StatelessWidget {
  const _SectionLabel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '⚙ 功能设置',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textOnSurface(context),
        ),
      ),
    );
  }
}

/// 菜单功能卡片：包含 5 个功能入口行
class _MenuCard extends StatelessWidget {
  const _MenuCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.glassDecoration(
        radius: 16,
        fill: AppTheme.glassFillStrong(context),
        context: context,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuRow(
            icon: PhosphorIconsLight.tag,
            iconBgColor: const Color(0x336366F1),
            label: '分类管理',
            route: '/categories',
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.08),
          ),
          _MenuRow(
            icon: PhosphorIconsLight.wallet,
            iconBgColor: const Color(0x33FBBF24),
            label: '预算设置',
            route: '/budget',
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.08),
          ),
          _MenuRow(
            icon: PhosphorIconsLight.arrowSquareOut,
            iconBgColor: const Color(0x3334D399),
            label: '数据导出',
            route: '/export',
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.08),
          ),
          _MenuRow(
            icon: PhosphorIconsLight.gear,
            iconBgColor: const Color(0x330EA5E9),
            label: '设置',
            route: '/settings',
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.textOnSurface(context).withValues(alpha: 0.08),
          ),
          _MenuRow(
            icon: PhosphorIconsLight.info,
            iconBgColor: const Color(0x26FFFFFF),
            label: '关于',
            route: '/about',
          ),
        ],
      ),
    );
  }
}

/// 菜单功能单行：图标 + 名称 + 右箭头
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String label;
  final String route;

  const _MenuRow({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 38×38 功能图标容器，圆角 11
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: AppTheme.textOnSurface(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // 功能名称文字
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textOnSurface(context),
                ),
              ),
            ),
            // 右箭头图标
            Icon(
              PhosphorIconsLight.caretRight,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
