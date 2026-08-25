import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化前台服务与主 isolate 的通信端口
  FlutterForegroundTask.initCommunicationPort();
  runApp(const ProviderScope(child: TimiApp()));
}
