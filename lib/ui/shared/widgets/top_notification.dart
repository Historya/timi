// 顶部通知弹窗组件 — 磨砂玻璃风格，从顶部滑入
//
// 统一替代所有 ScaffoldMessenger.showSnackBar 调用。
// 支持 info/warning/error/success 四种类型，自动 3 秒后消失。
//
// 使用方式:
//   TopNotification.show(context, message: '操作成功');
//   TopNotification.show(context, message: '出错了', type: TopNotificationType.error);

import 'package:flutter/material.dart';
import 'package:timi/core/theme/app_theme.dart';

/// 通知类型枚举
enum TopNotificationType {
  /// 信息提示（绿色）
  info,

  /// 警告提示（黄色）
  warning,

  /// 错误提示（红色）
  error,

  /// 成功提示（绿色）
  success,
}

/// 顶部通知弹窗 — 静态辅助类
///
/// 通过 Overlay 在屏幕顶部展示磨砂玻璃风格的通知横幅。
class TopNotification {
  TopNotification._();

  /// 显示顶部通知
  ///
  /// [context] 用于获取 Overlay 和主题（当提供了 [overlay] 参数时，context 仅用
  ///           于主题获取，不再用于查找 Overlay）
  /// [message] 通知文本内容
  /// [type] 通知类型，决定图标和颜色（默认 info）
  /// [icon] 自定义图标，传 null 则根据 type 自动选择
  /// [duration] 展示时长，默认 3 秒
  /// [showClose] 是否显示关闭按钮
  /// [overlay] 可选的 OverlayState，当 context 无法找到 Overlay 时使用
  ///           （如 BudgetAlertWatcher 位于 MaterialApp 上层）
  static void show(
    BuildContext context, {
    required String message,
    TopNotificationType type = TopNotificationType.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    bool showClose = true,
    OverlayState? overlay,
  }) {
    // 根据类型选择默认图标和颜色
    late final IconData defaultIcon;
    late final Color defaultColor;

    switch (type) {
      case TopNotificationType.info:
        defaultIcon = Icons.info_outline;
        defaultColor = const Color(0xFF69DB7C); // 绿色
      case TopNotificationType.warning:
        defaultIcon = Icons.warning_amber_rounded;
        defaultColor = const Color(0xFFFBBF24); // 黄色
      case TopNotificationType.error:
        defaultIcon = Icons.error_outline;
        defaultColor = const Color(0xFFF87171); // 红色
      case TopNotificationType.success:
        defaultIcon = Icons.check_circle_outline;
        defaultColor = const Color(0xFF4ADE80); // 绿色
    }

    // 优先使用传入的 overlay，否则从 context 向上查找
    final effectiveOverlay = overlay ?? Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _TopNotificationWidget(
        message: message,
        icon: icon ?? defaultIcon,
        iconColor: defaultColor,
        showClose: showClose,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );

    effectiveOverlay.insert(entry);
  }
}

/// 顶部通知的内部 Widget
class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final bool showClose;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.showClose,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器：入场（250ms）+ 停留 + 出场（250ms）
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // 播放入场动画
    _controller.forward();

    // 自动消失
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    // 出场动画（反向）后再移除
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding.top;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          // 只保留顶部 safe area，底部不需要
          top: false,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: padding + 8),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 360,
                    minHeight: 52,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.glassFillAccent(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.glassStroke(context),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 左侧图标
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          child: Icon(
                            widget.icon,
                            color: widget.iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 消息文本
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textOnSurface(
                                context,
                              ).withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        // 关闭按钮
                        if (widget.showClose)
                          GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.close,
                                color: AppTheme.textOnSurface(
                                  context,
                                ).withValues(alpha: 0.6),
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
