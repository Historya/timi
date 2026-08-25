import 'dart:async';
import 'dart:convert';
import 'dart:io' show WebSocket;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:timi/services/asr_service.dart';

/// 阿里云 DashScope 实时语音识别引擎实现
///
/// 通过 WebSocket 协议连接 DashScope 的 paraformer-realtime-v2 模型。
/// 协议地址：wss://dashscope.aliyuncs.com/api-ws/v1/inference
///
/// 通信流程：
/// 1. 建立 WebSocket → 发送 run-task JSON
/// 2. 收到 task-started → 发送 PCM 音频帧
/// 3. 持续接收 result-generated → 通过 transcriptStream 输出
/// 4. 发 finish-task → 收 task-finished → 关闭连接
class DashScopeAsrService implements AsrService {
  static const String _defaultUrl =
      'wss://dashscope.aliyuncs.com/api-ws/v1/inference';
  static const String _defaultModel = 'paraformer-realtime-v2';

  WebSocketChannel? _channel;
  String? _taskId;
  bool _isConnected = false;
  String _currentTranscript = '';

  final _transcriptController = StreamController<String>.broadcast();
  final _stateController =
      StreamController<AsrConnectionState>.broadcast();
  Completer<String> _completer = Completer<String>();

  @override
  String get engineId => 'dashscope';

  @override
  String get displayName => '阿里云 DashScope';

  @override
  bool get isConnected => _isConnected;

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
    // 重置 completer 和 transcript，确保每次连接都是全新状态
    _completer = Completer<String>();
    _currentTranscript = '';

    // 更新连接状态为连接中
    _stateController.add(AsrConnectionState.connecting);

    try {
      // 生成唯一的任务 ID
      _taskId = const Uuid().v4();

      // 构建 WebSocket 连接，在请求头中添加 Authorization
      final ws = await WebSocket.connect(
        _defaultUrl,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );
      _channel = IOWebSocketChannel(ws);

      // 发送 run-task 指令
      final runTaskPayload = {
        'header': {
          'action': 'run-task',
          'task_id': _taskId,
          'streaming': 'out',
        },
        'payload': {
          'model': model.isNotEmpty ? model : _defaultModel,
          'parameters': {
            'format': 'pcm',
            'sample_rate': 16000,
            'enable_partial_result': true,
            'enable_punctuation_prediction': true,
          },
          'input': {},
        },
      };
      _channel!.sink.add(jsonEncode(runTaskPayload));

      _isConnected = true;
      _stateController.add(AsrConnectionState.connected);

      // 监听服务端消息
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _stateController.add(AsrConnectionState.error);
          if (!_completer.isCompleted) {
            _completer.completeError(error);
          }
        },
        onDone: () {
          _isConnected = false;
          _stateController.add(AsrConnectionState.disconnected);
        },
      );
    } catch (e) {
      _isConnected = false;
      _stateController.add(AsrConnectionState.error);
      rethrow;
    }
  }

  /// 测试用：从服务端 JSON 响应中提取识别文本
  @visibleForTesting
  static String? extractTranscriptFromResponse(Map<String, dynamic> data) {
    final header = data['header'] as Map<String, dynamic>?;
    if (header == null) return null;

    final action = header['action'] as String?;
    final statusCode = header['status_code'] as int?;

    // DashScope API 状态码：2xxxxx 表示成功，4xxxxx 表示客户端错误，5xxxxx 表示服务端错误
    if (statusCode != null && statusCode >= 400000 && action != 'task-failed') {
      return null;
    }

    if (action == 'result-generated' || action == 'task-finished') {
      final payload = data['payload'] as Map<String, dynamic>?;
      if (payload == null) return null;
      final output = payload['output'] as Map<String, dynamic>?;
      if (output == null) return null;
      final sentence = output['sentence'] as Map<String, dynamic>?;
      if (sentence == null) return null;
      return sentence['text'] as String?;
    }

    return null;
  }

  /// 处理 WebSocket 接收到的消息
  void _handleMessage(dynamic message) {
    if (message is! String) return;
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final text = extractTranscriptFromResponse(data);
      if (text != null && text.isNotEmpty) {
        _currentTranscript = text;
        _transcriptController.add(text);
      }

      final header = data['header'] as Map<String, dynamic>?;
      final payload = data['payload'] as Map<String, dynamic>?;
      final action = header?['action'] as String?;
      final statusCode = header?['status_code'] as int?;

      switch (action) {
        case 'task-started':
          _stateController.add(AsrConnectionState.listening);
          break;
        case 'task-finished':
          if (!_completer.isCompleted) {
            _completer.complete(_currentTranscript);
          }
          _stateController.add(AsrConnectionState.disconnected);
          break;
        case 'task-failed':
          final msg = payload?['message'] as String? ?? 'Unknown error';
          if (!_completer.isCompleted) {
            _completer.completeError(Exception(msg));
          }
          _stateController.add(AsrConnectionState.error);
          break;
      }

      // DashScope API 状态码：2xxxxx 表示成功，4xxxxx 表示错误
      if (statusCode != null && statusCode >= 400000 && action != 'task-failed') {
        final msg = payload?['message'] as String? ?? 'Error code: $statusCode';
        if (!_completer.isCompleted) {
          _completer.completeError(Exception(msg));
        }
        _stateController.add(AsrConnectionState.error);
      }
    } catch (_) {}
  }

  @override
  void sendAudio(Uint8List pcmChunk) {
    if (_channel == null || !_isConnected) return;
    try {
      _channel!.sink.add(pcmChunk);
    } catch (_) {
      // 连接已关闭时静默丢弃，避免音频流回调抛出异常
    }
  }

  @override
  Future<String> stop() async {
    if (_channel == null || !_isConnected) {
      return _currentTranscript;
    }

    try {
      // 发送 finish-task 指令
      final finishTaskPayload = {
        'header': {
          'action': 'finish-task',
          'task_id': _taskId,
        },
      };
      _channel!.sink.add(jsonEncode(finishTaskPayload));

      // 等待最终结果（带超时）
      final result = await _completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => _currentTranscript,
      );

      return result;
    } catch (e) {
      return _currentTranscript;
    }
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _completer = Completer<String>();
    await _channel?.sink.close();
    _channel = null;
    _currentTranscript = '';
    _stateController.add(AsrConnectionState.disconnected);
  }

  /// 释放资源
  void dispose() {
    _transcriptController.close();
    _stateController.close();
  }
}
