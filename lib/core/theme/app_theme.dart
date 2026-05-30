import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // 渐变颜色
  static const Color gradientStart = Color(0xFF4158D0);
  static const Color gradientMid = Color(0xFFC850C0);
  static const Color gradientEnd = Color(0xFFFFCC70);

  // 暗色主题表面颜色
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color glassWhite26 = Color(0x26FFFFFF);
  static const Color glassWhite1f = Color(0x1FFFFFFF);
  static const Color glassWhite1a = Color(0x1AFFFFFF);
  static const Color glassWhite40 = Color(0x40FFFFFF);
  static const Color glassStroke26 = Color(0x26FFFFFF);
  static const Color glassStroke33 = Color(0x33FFFFFF);
  static const Color glassStroke40 = Color(0x40FFFFFF);

  // 浅色主题表面颜色
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// 浅色主题背景颜色（浅灰色，与白色卡片形成对比）
  static const Color surfaceLightBg = Color(0xFFF5F5F5);
  static const Color glassBlack0f = Color(0x0F000000);
  static const Color glassBlack14 = Color(0x14000000);
  static const Color glassBlack1a = Color(0x1A000000);
  static const Color glassBlack26 = Color(0x26000000);
  static const Color glassBlack40 = Color(0x40000000);
  static const Color glassStrokeLight = Color(0x1A000000);

  // 语义颜色
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentYellow = Color(0xFFF59E0B);

  // 暗色主题文字颜色（保留向后兼容）
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x80FFFFFF);

  /// 根据当前主题返回表面文字颜色（浅色主题下为黑色）
  static Color textOnSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black;
  }

  /// 表面次要文字颜色（70% 透明度）
  static Color textOnSurfaceSecondary(BuildContext context) {
    return textOnSurface(context).withValues(alpha: 0.7);
  }

  /// 表面第三级文字颜色（60% 透明度，浅色主题下提升可读性）
  static Color textOnSurfaceTertiary(BuildContext context) {
    return textOnSurface(context).withValues(alpha: 0.6);
  }

  /// 毛玻璃填充色（最浅层）
  static Color glassFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? glassWhite1f : surfaceLight;
  }

  /// 毛玻璃描边色
  static Color glassStroke(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? glassStroke33 : glassStrokeLight;
  }

  /// 毛玻璃填充色（中等层）
  static Color glassFillStrong(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? glassWhite1a : surfaceLight;
  }

  /// 毛玻璃填充色（最深层）
  static Color glassFillAccent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? glassWhite40 : surfaceLight;
  }
  

    /// 毛玻璃填充色（最深层）
  static Color glassFillNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? glassWhite40 : glassBlack0f;
  }

  /// 根据主题返回合适的阴影颜色
  /// 暗色模式用黑色阴影，浅色模式用极淡阴影避免视觉污染
  static Color glassShadowColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.black.withValues(alpha: 0.3) // 暗色：半透明黑色阴影
        : Colors.black.withValues(alpha: 0.08); // 浅色：极淡阴影避免脏污感
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        secondary: glassWhite40,
        surface: surfaceDark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }

  /// 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: accentBlue,
      colorScheme: ColorScheme.light(
        primary: accentBlue,
        secondary: accentBlue,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      useMaterial3: true,
    );
  }

  /// 毛玻璃装饰（无阴影）
  ///
  /// [context] 传入后可获得主题感知的默认颜色（深色→浅色自动适配）。
  /// 当不传 [context] 或无明确 [fill] 时，默认用 dark 的颜色值以保持向后兼容。
  static BoxDecoration glassDecoration({
    double radius = 16,
    Color? fill,
    Color? stroke,
    double strokeWidth = 1,
    BuildContext? context,
  }) {
    return BoxDecoration(
      color: fill ?? (context != null ? glassFill(context) : glassWhite1f),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            stroke ?? (context != null ? glassStroke(context) : glassStroke33),
        width: strokeWidth,
      ),
    );
  }

  /// 完整毛玻璃装饰（含阴影）
  ///
  /// [context] 传入后可获得主题感知的默认颜色和阴影色。
  /// 不传 [context] 时默认用 dark 色值。
  static BoxDecoration glassDecorationFull({
    double radius = 16,
    Color? fill,
    Color? stroke,
    double strokeWidth = 1,
    List<BoxShadow>? shadows,
    BuildContext? context,
  }) {
    return BoxDecoration(
      color: fill ?? (context != null ? glassFill(context) : glassWhite1f),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            stroke ?? (context != null ? glassStroke(context) : glassStroke33),
        width: strokeWidth,
      ),
      boxShadow:
          shadows ??
          [
            BoxShadow(
              color: context != null
                  ? glassShadowColor(context)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }
}
