import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/core/router/app_router.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/ui/shared/widgets/budget_alert_watcher.dart';

class TimiApp extends ConsumerWidget {
  const TimiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // 监听语言切换，触发 GoRouter 重建页面
    ref.listen(localeProvider, (prev, next) {
      if (prev != next) {
        ref.read(localeRefreshProvider).value++;
      }
    });
    return BudgetAlertWatcher(
      child: MaterialApp.router(
        title: 'Timi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ref.watch(themeModeProvider),
        locale: ref.watch(localeProvider),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}