import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show WebSocket;
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' show Hmac, sha1;
import 'package:meta/meta.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:timi/services/asr_service.dart';

/// 腾讯云 ASR 实时语音识别引擎
///
/// 基于 docs/tx_asr/index.html 参考实现。
/// 协议文档：https://cloud.tencent.com/document/product/1093/48982
///
/// 通信流程：
/// 1. HMAC-SHA1 签名构建 WebSocket URL（所有参数在 URL query 中）
/// 2. 建立 WebSocket 连接，直接发送 PCM 音频数据
/// 3. 接收 code/result.voice_text_str/final 协议消息
/// 4. 发送 {"type":"end"} 结束会话
class TencentAsrService implements AsrService {
  /// 腾讯云 ASR 服务主机名（不含协议前缀，用于签名计算）
  static const String _defaultHost = 'asr.cloud.tencent.com';
  /// 腾讯云 ASR 服务路径
  static const String _defaultPath = '/asr/v2';
  /// 默认引擎模型：中文普通话通用 16kHz
  static const String _defaultEngine = '16k_zh';
  /// 音频采样率（Hz）
  static const int _defaultSampleRate = 16000;
  /// 音频格式：1 = PCM
  static const int _defaultVoiceFormat = 1;
  /// 签名有效期（秒）
  static const int _signExpireDuration = 86400;
  // 腾讯云服务凭证
  final String appId;
  final String secretId;
  final String secretKey;
  WebSocketChannel? _channel;
  String _currentVoiceId = '';
  bool _isConnected = false;
  String _currentTranscript = '';
  final _transcriptController = StreamController<String>.broadcast();
  final _stateController = StreamController<AsrConnectionState>.broadcast();
  late Completer<String> _completer;
  TencentAsrService({
    required this.appId,
    required this.secretId,
    required this.secretKey,
  }) {
    _completer = Completer<String>();
  }
  @override
  String get engineId => 'tencent';
  @override
  String get displayName => '腾讯云 ASR';
  @override
  bool get isConnected => _isConnected;
  @override
  Stream<String> get transcriptStream => _transcriptController.stream;
  @override
  Stream<AsrConnectionState> get connectionStateStream =>
      _stateController.stream;
  // ============================================================
  //  签名计算 & URL 构建
  // ============================================================
  /// 计算 HMAC-SHA1 签名，返回 Base64 编码结果
  @visibleForTesting
  static String calcHmacSha1(String key, String data) {
    final hmac = Hmac(sha1, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return base64.encode(digest.bytes);
  }
  /// 生成唯一的 voice_id（格式：dart_ + 毫秒时间戳）
  static String _generateVoiceId() {
    return 'dart_${DateTime.now().millisecondsSinceEpoch}';
  }
  /// 构建带签名的 WebSocket 连接 URL
  ///
  /// 签名步骤（对齐参考实现 docs/tx_asr/index.html 第 54-67 行）：
  /// 1. 构建参数字典（含 voice_id/engine_model_type/sample_rate 等）
  /// 2. 参数按字典序排序，拼接 query string
  /// 3. 签名原文：{host}{path}/{appId}?{sorted_query_string}
  /// 4. HMAC-SHA1 加密 + Base64 编码
  /// 5. 使用 Uri.https() 构建完整 URL
  ///
  /// [engineOverride] 可选，覆盖 URL 中的 engine_model_type
  @visibleForTesting
  String buildWsUrl({String engineOverride = ''}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expired = timestamp + _signExpireDuration;
    final nonce = Random().nextInt(999999999);
    _currentVoiceId = _generateVoiceId();
    // 所有参数（不含 signature，用于签名计算）
    final params = <String, String>{
      'engine_model_type':
      engineOverride.isNotEmpty ? engineOverride : _defaultEngine,
      'expired': expired.toString(),
      'nonce': nonce.toString(),
      'sample_rate': _defaultSampleRate.toString(),
      'secretid': secretId,
      'timestamp': timestamp.toString(),
      'voice_format': _defaultVoiceFormat.toString(),
      'voice_id': _currentVoiceId,
    };
    // 参数按字典序排序后拼接 query string（用于签名原文）
    final sortedKeys = params.keys.toList()..sort();
    final queryString = sortedKeys.map((k) => '$k=${params[k]}').join('&');
    // 签名原文：host/path/appId?queryString（不含 wss://）
    final signStr = '$_defaultHost$_defaultPath/$appId?$queryString';
    // 计算签名
    final signature = calcHmacSha1(secretKey, signStr);
    // 使用 Uri.https() 构建完整 URL（自动处理参数编码）
    final uri = Uri.https(
      _defaultHost,
      '$_defaultPath/$appId',
      {
        ...params,
        'signature': signature,
      },
    );
    // 将 https:// 替换为 wss:// 得到最终 WebSocket URL
    final wsUrl = uri.toString().replaceFirst('https://', 'wss://');
    // 调试日志（secretid 仅保留前 8 位，避免泄露）
    final maskedUrl = wsUrl.replaceAll(
      RegExp(r'secretid=[^&]+'),
      'secretid=${secretId.substring(0, 8)}***',
    );
    developer.log('[TencentASR] URL: $maskedUrl', name: 'TencentASR');
    return wsUrl;
  }
  // ============================================================
  //  响应消息解析
  // ============================================================
  /// 从服务端 JSON 响应中提取识别文本
  ///
  /// 腾讯云 ASR 响应格式：
  ///   {"code":0,"result":{"voice_text_str":"你好"}}
  @visibleForTesting
  static String? extractTranscriptFromResponse(Map<String, dynamic> data) {
    // 检查 code 字段，非零表示错误
    final code = data['code'] as int?;
    if (code != null && code != 0) return null;
    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return null;
    return result['voice_text_str'] as String?;
  }
  // ============================================================
  //  连接生命周期
  // ============================================================
  @override
  Future<void> connect({required String apiKey, required String model}) async {
    // 重置 completer 和 transcript，确保每次连接都是全新状态
    _completer = Completer<String>();
    _currentTranscript = '';
    // 更新连接状态为连接中
    _stateController.add(AsrConnectionState.connecting);
    try {
      // 构建带签名的 WebSocket URL（所有参数在 URL 中，不发送 start 帧）
      final wsUrl = buildWsUrl(engineOverride: model);
      final ws = await WebSocket.connect(wsUrl);
      _channel = IOWebSocketChannel(ws);
      _isConnected = true;
      _stateController.add(AsrConnectionState.connected);
      // 监听服务端消息
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          developer.log('[TencentASR] 错误: $error', name: 'TencentASR');
          _stateController.add(AsrConnectionState.error);
          if (!_completer.isCompleted) {
            _completer.completeError(error);
          }
        },
        onDone: () {
          developer.log('[TencentASR] 连接关闭', name: 'TencentASR');
          _isConnected = false;
          _stateController.add(AsrConnectionState.disconnected);
          if (!_completer.isCompleted) {
            _completer.complete(_currentTranscript);
          }
        },
      );
    } catch (e) {
      _isConnected = false;
      _stateController.add(AsrConnectionState.error);
      rethrow;
    }
  }
  /// 处理 WebSocket 服务端消息
  ///
  /// 腾讯云 ASR 响应协议（对齐 docs/tx_asr/index.html 第 107-128 行）：
  /// - 成功：{"code":0,"result":{"voice_text_str":"文本"}}
  /// - 结束：{"final":1}
  /// - 错误：{"code":4001,"message":"描述"}
  void _handleMessage(dynamic message) {
    developer.log('asr message: $message', name: 'TencentASR');
    // 忽略二进制消息
    if (message is! String) return;
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      // 检查错误码
      final code = data['code'] as int?;
      if (code != null && code != 0) {
        final errMsg = data['message'] as String? ?? 'ASR 错误码: $code';
        developer.log('[TencentASR] 服务端错误: $errMsg', name: 'TencentASR');
        _stateController.add(AsrConnectionState.error);
        if (!_completer.isCompleted) {
          _completer.completeError(Exception(errMsg));
        }
        return;
      }
      // 检测 final 结束标记
      if (data['final'] == 1) {
        if (!_completer.isCompleted) {
          _completer.complete(_currentTranscript);
        }
        _stateController.add(AsrConnectionState.disconnected);
        return;
      }
      // 提取识别结果（中间结果或最终结果）
      final text = extractTranscriptFromResponse(data);
      if (text != null && text.isNotEmpty) {
        _currentTranscript = text;
        _transcriptController.add(text);
      }
    } catch (_) {
      // 忽略 JSON 解析异常
    }
  }
  // ============================================================
  //  音频发送 & 会话结束
  // ============================================================
  @override
  void sendAudio(Uint8List pcmChunk) {
    if (_channel == null || !_isConnected) return;
    try {
      // 发送原始 PCM Int16 二进制数据
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
      // 发送 end 帧，通知服务器结束识别
      _channel!.sink.add(jsonEncode({'type': 'end'}));
      // 等待最终结果（最长等待 30 秒）
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