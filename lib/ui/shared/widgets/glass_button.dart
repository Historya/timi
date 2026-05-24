// 毛玻璃按钮组件，支持按压缩放动画
import 'package:flutter/material.dart';
import 'package:timi/core/theme/app_theme.dart';

class GlassButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double radius;
  final double? width;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.radius = 26,
    this.width,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: widget.width,
          height: 52,
          child: Container(
            decoration: AppTheme.glassDecoration(
              radius: widget.radius,
              fill: AppTheme.glassFillAccent(context),
              context: context,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        widget.icon,
                        color: AppTheme.textOnSurface(context),
                        size: 20,
                      ),
                    ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
