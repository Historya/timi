import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:timi/core/theme/app_theme.dart';

class GlassHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;

  const GlassHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: Icon(PhosphorIconsLight.arrowLeft, color: AppTheme.textOnSurface(context)),
              onPressed: () => context.pop(),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textOnSurface(context)),
            ),
          ),
          if (actions != null) ...actions! else const SizedBox(width: 48),
        ],
      ),
    );
  }
}