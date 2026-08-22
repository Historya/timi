// 设备离线语音识别实现
//
// 使用 speech_to_text 插件调用系统内置语音识别服务
// 支持 Android（Google 语音识别）和 iOS（Siri）的内置识别
// 无需联网，无需 API Key

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:timi/services/asr_service.dart';

/// 设备离线语音识别引擎实现
///
/// 使用系统内置语音识别服务，无需联网和 API Key。
/// Android 使用 Google 语音识别，iOS 使用 Siri。
///
/// 与线上 ASR 引擎的关键差异：
/// - 无需调用 [connect] 的 apiKey 参数
/// - [sendAudio] 为空操作（系统录音由 speech_to_text 内部管理）
/// - [connect] 内部直接启动识别（初始化即监听）
class OfflineAsrService implements AsrService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  final _transcriptController = StreamController<String>.broadcast();
  final _stateController =
      StreamController<AsrConnectionState>.broadcast();

  bool _isListening = false;
  String _lastTranscript = '';
  Completer<String> _completer = Completer<String>();

  @override
  String get engineId => 'offline';

  @override
  String get displayName => '设备离线识别';

  @override
  bool get isConnected => _isListening;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<AsrConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  Future<void> connect({
    required String apiKey,
    required String model,
  }) async {
    // 重置状态，确保每次连接全新开始
    _completer = Completer<String>();
    _lastTranscript = '';

    _stateController.add(AsrConnectionState.connecting);

    try {
      // 初始化 speech_to_text 插件
      final available = await _speech.initialize(
        onError: (error) {
          debugPrint('[OfflineASR] 错误: ${error.errorMsg}');
          _stateController.add(AsrConnectionState.error);
          if (!_completer.isCompleted) {
            _completer.completeError(Exception(error.errorMsg));
          }
        },
        onStatus: (status) {
          debugPrint('[OfflineASR] 状态变化: $status');
          // 当状态为 done 或 notListening 且当前正在监听时
          // 视为识别自然结束，complete 最终结果
          if ((status == 'done' || status == 'notListening') &&
              _isListening &&
              _lastTranscript.isNotEmpty) {
            _isListening = false;
            if (!_completer.isCompleted) {
              _completer.complete(_lastTranscript);
            }
            _stateController.add(AsrConnectionState.disconnected);
          }
        },
      );

      if (!available) {
        _stateController.add(AsrConnectionState.error);
        throw Exception('设备不支持语音识别或权限被拒绝');
      }

      // 直接开始监听（离线模式下，connect 即启动识别）
      _stateController.add(AsrConnectionState.listening);
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.confirmation,
        ),
        onResult: (result) {
          final text = result.recognizedWords;
          _lastTranscript = text;

          // 实时输出识别结果
          _transcriptController.add(text);

          // 最终结果（语音结束自动触发）
          if (result.finalResult) {
            debugPrint('[OfflineASR] 最终结果: $text');
          }
        },
        localeId: 'zh_CN',
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 10),
      );

      _isListening = true;
      debugPrint('[OfflineASR] 识别已启动');
    } catch (e) {
      _isListening = false;
      _stateController.add(AsrConnectionState.error);
      // 将平台异常转为友好提示
      if (e is PlatformException && e.code == 'recognizerNotAvailable') {
        throw Exception('speech_not_available');
      }
      rethrow;
    }
  }

  @override
  void sendAudio(Uint8List pcmChunk) {
    // 离线 ASR 由 speech_to_text 内部管理麦克风
    // 此方法为空操作，与线上引擎接口兼容
  }

  @override
  Future<String> stop() async {
    if (!_isListening) {
      debugPrint('[OfflineASR] 停止时未在监听');
      return _lastTranscript;
    }

    try {
      debugPrint('[OfflineASR] 停止监听');
      await _speech.stop();
      _isListening = false;

      // 如果 completer 尚未完成，用当前文本完成
      if (!_completer.isCompleted) {
        _completer.complete(_lastTranscript);
      }

      return _lastTranscript;
    } catch (e) {
      debugPrint('[OfflineASR] 停止出错: $e');
      return _lastTranscript;
    }
  }

  @override
  Future<void> disconnect() async {
    _isListening = false;
    _completer = Completer<String>();

    try {
      await _speech.stop();
      await _speech.cancel();
    } catch (_) {}

    _lastTranscript = '';
    _stateController.add(AsrConnectionState.disconnected);
    debugPrint('[OfflineASR] 已断开');
  }

  /// 释放资源
  void dispose() {
    _transcriptController.close();
    _stateController.close();
  }

  /// 检查设备是否支持语音识别
  static Future<bool> isDeviceSupported() async {
    try {
      final speech = stt.SpeechToText();
      return await speech.initialize();
    } catch (_) {
      return false;
    }
  }
}
