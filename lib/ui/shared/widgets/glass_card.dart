// 毛玻璃卡片容器组件
import 'package:flutter/material.dart';
import 'package:timi/core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? fill;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.radius = 16,
    this.fill,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        radius: radius,
        fill: fill ?? AppTheme.glassFill(context),
        context: context,
      ),
      child: child,
    );
  }
}
