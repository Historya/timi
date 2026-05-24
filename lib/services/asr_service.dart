import 'dart:async';
import 'dart:typed_data';

/// 语音识别引擎抽象接口
///
/// 所有 ASR（自动语音识别）引擎必须实现此接口。
/// 目前实现：DashScopeAsrService（阿里云）
/// 预留：BaiduAsrService、TencentAsrService、OfflineAsrService
abstract class AsrService {
  /// 引擎唯一标识（用于 SettingsTable 存储和配置）
  String get engineId;

  /// 引擎显示名称（用于设置页面展示）
  String get displayName;

  /// 初始化连接 ASR 服务
  ///
  /// [apiKey] 认证密钥
  /// [model] 模型名称（如 paraformer-realtime-v2）
  Future<void> connect({
    required String apiKey,
    required String model,
  });

  /// 发送一帧 PCM 音频数据
  ///
  /// [pcmChunk] PCM 16kHz 16-bit mono 音频数据块
  void sendAudio(Uint8List pcmChunk);

  /// 实时识别文本流
  ///
  /// 每收到一次 result-generated 事件，发射一次当前最佳识别结果
  Stream<String> get transcriptStream;

  /// 停止识别并获取最终完整文本
  ///
  /// 返回本次会话的完整识别文本
  Future<String> stop();

  /// 断开 WebSocket 连接，释放资源
  Future<void> disconnect();

  /// 当前是否已连接
  bool get isConnected;

  /// 当前连接状态流
  Stream<AsrConnectionState> get connectionStateStream;
}

/// ASR 连接状态枚举
enum AsrConnectionState {
  disconnected,
  connecting,
  connected,
  listening,
  error,
}
