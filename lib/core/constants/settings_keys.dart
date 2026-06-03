/// SettingsTable 键常量
///
/// 包含数据库中所有 settings 条目的 key 值，替换项目中的硬编码字符串。
/// 注意：以下常量同时定义了 ASR 引擎键和语义解析键，区分同名但用途不同的 Key。
///
/// 替换项目中所有硬编码的设置 key 魔法字符串。
class SettingsKeys {
  SettingsKeys._();

  /// 语言偏好
  static const String language = 'language';

  /// 主题模式
  static const String themeMode = 'theme_mode';

  /// ASR 语音识别引擎类型
  static const String asrEngine = 'asr_engine';

  /// 语义解析引擎类型
  static const String semanticParserEngine = 'semantic_parser_engine';

  /// 腾讯云 ASR AppId
  static const String tencentAppId = 'tencent_app_id';

  /// 腾讯云 ASR SecretId
  static const String tencentSecretId = 'tencent_secret_id';

  /// 腾讯云 ASR SecretKey
  static const String tencentSecretKey = 'tencent_secret_key';

  /// DashScope ASR API Key（语音识别）
  static const String dashscopeApiKey = 'dashscope_api_key';

  /// DashScope LLM API Key（语义解析）
  static const String dashscopeLlmApiKey = 'dashscope_llm_api_key';

  /// 预算提醒开关
  static const String budgetAlert = 'budget_alert';

  /// 默认货币单位
  static const String currency = 'currency';
}

/// ASR 引擎类型常量
class AsrEngineType {
  AsrEngineType._();

  /// 阿里云 DashScope ASR
  static const String dashscope = 'dashscope';

  /// 腾讯云 ASR
  static const String tencent = 'tencent';
}

/// 语义解析引擎类型常量
class SemanticParserEngineType {
  SemanticParserEngineType._();

  /// 阿里云 DashScope 语义解析
  static const String dashscope = 'dashscope';
}

/// 主题模式存储值常量
class ThemeModeValue {
  ThemeModeValue._();

  /// 深色模式
  static const String dark = 'dark';

  /// 浅色模式
  static const String light = 'light';

  /// 跟随系统
  static const String system = 'system';
}
