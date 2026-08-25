import 'package:flutter/material.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/services/keep_alive_service.dart';

/// 后台保活启动器
///
/// 应用启动后自动开启前台服务，避免进程被系统立即回收。
/// 放在 MaterialApp 的 builder 中，以便获取本地化文案。
class KeepAliveStarter extends StatefulWidget {
  final Widget child;

  const KeepAliveStarter({super.key, required this.child});

  @override
  State<KeepAliveStarter> createState() => _KeepAliveStarterState();
}

class _KeepAliveStarterState extends State<KeepAliveStarter> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // 首帧渲染后异步启动，避免阻塞首帧
    WidgetsBinding.instance.addPostFrameCallback((_) => _startKeepAlive());
  }

  /// 启动后台保活前台服务
  Future<void> _startKeepAlive() async {
    if (_started) return;
    _started = true;
    final l10n = AppLocalizations.of(context);
    await KeepAliveService.start(
      channelName: l10n.keepAliveChannelName,
      channelDescription: l10n.keepAliveChannelDesc,
      notificationTitle: l10n.keepAliveNotificationTitle,
      notificationText: l10n.keepAliveNotificationText,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
