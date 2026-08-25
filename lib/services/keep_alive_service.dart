import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// 后台保活前台服务
///
/// 基于 flutter_foreground_task 实现 Android 前台服务保活：
/// 应用启动时自动开启，常驻通知 + 开机自启 + 被系统杀死后自动重启，
/// 避免应用退到后台后进程被立即回收。
///
/// 注意：电池优化策略由用户在系统「电池/耗电」设置中自行选择，
/// 应用内不做强制请求。
class KeepAliveService {
  KeepAliveService._();

  /// 服务唯一 ID
  static const int serviceId = 20260822;

  /// 当前服务是否正在运行
  static Future<bool> isRunning() => FlutterForegroundTask.isRunningService;

  /// 启动前台服务（若已在运行则跳过）
  ///
  /// 内部依次完成：插件初始化 → Android 13+ 通知权限请求 → 启动服务。
  static Future<void> start({
    required String channelName,
    required String channelDescription,
    required String notificationTitle,
    required String notificationText,
  }) async {
    // 已在运行时直接返回，避免重复启动（含开机自启后进程已存在的情况）
    if (await FlutterForegroundTask.isRunningService) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'keep_alive_service',
        channelName: channelName,
        channelDescription: channelDescription,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowAutoRestart: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    // Android 13+ 需要通知权限，否则常驻通知不可见
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: serviceId,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      notificationIcon: null,
      notificationInitialRoute: '/',
      callback: keepAliveTaskCallback,
    );
    if (result is ServiceRequestFailure) {
      debugPrint('启动保活服务失败: ${result.error}');
    }
  }
}

/// 前台服务回调（必须是顶层函数，并带 vm:entry-point 注解）
@pragma('vm:entry-point')
void keepAliveTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveTaskHandler());
}

/// 空任务处理器：仅保持后台 isolate 存活，不执行周期任务
class _KeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
