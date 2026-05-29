// 关于页面，展示应用信息、菜单链接和版权声明
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
              _buildAppIcon(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMenuCard(context),
              ),
              const Spacer(),
              _buildCopyright(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 头部：返回箭头 24px + "关于" 20px 粗体居中 + 间隔块
  Widget _buildHeader(BuildContext context) {
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
              '关于',
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

  /// 应用图标区域：居中纵向，间距 8，上边距 32
  Widget _buildAppIcon(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                PhosphorIconsLight.currencyCircleDollar,
                size: 40,
                color: Color(0xFF4ADE80),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Timi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnSurface(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '极简语音记账',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }

  /// 关于菜单卡片：圆角 16，毛玻璃背景
  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassFillStrong(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.glassStroke(context),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _buildMenuItem(
            icon: PhosphorIconsLight.note,
            title: '更新日志',
            context: context,
          ),
          Divider(
            color: AppTheme.glassFill(context),
            height: 1,
          ),
          _buildMenuItem(
            icon: PhosphorIconsLight.fileText,
            title: '用户协议',
            context: context,
          ),
          Divider(
            color: AppTheme.glassFill(context),
            height: 1,
          ),
          _buildMenuItem(
            icon: PhosphorIconsLight.lock,
            title: '隐私政策',
            context: context,
          ),
        ],
      ),
    );
  }

  /// 菜单行：高 52，间距 12，水平填充 [0,16]
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required BuildContext context,
  }) {
    return SizedBox(
      height: 52,
      child: GestureDetector(
        onTap: () {
          TopNotification.show(context,
              message: '$title（待实现）',
              type: TopNotificationType.info);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: AppTheme.textOnSurface(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textOnSurface(context),
                  ),
                ),
              ),
              Icon(
                PhosphorIconsLight.caretRight,
                size: 18,
                color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 版权信息：居中 12px
  Widget _buildCopyright() {
    return const Text(
      '(c) 2024 Timi Team',
      style: TextStyle(
        fontSize: 12,
        color: Color(0x40FFFFFF),
      ),
      textAlign: TextAlign.center,
    );
  }
}
