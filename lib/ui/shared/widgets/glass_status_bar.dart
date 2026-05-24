import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';

class GlassStatusBar extends StatelessWidget {
  const GlassStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textOnSurface(context)),
          ),
          Row(
            children: [
              Icon(PhosphorIconsLight.wifiHigh, size: 16, color: AppTheme.textOnSurface(context)),
              const SizedBox(width: 6),
              Icon(PhosphorIconsLight.batteryFull, size: 16, color: AppTheme.textOnSurface(context)),
            ],
          ),
        ],
      ),
    );
  }
}