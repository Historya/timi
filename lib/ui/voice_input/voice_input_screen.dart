import 'dart:async';
import 'dart:typed_data';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:record/record.dart';
import 'package:drift/drift.dart' show Value;

import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/services/asr_service.dart';
import 'package:timi/services/semantic_parser.dart';

/// 语音输入页面状态枚举
enum _VoiceInputState {
  /// 初始状态，等待用户点击录音
  idle,

  /// 正在录音中
  recording,

  /// 停止录音后正在 AI 语义解析中
  parsing,

  /// 识别完成，显示解析结果
  result,
}

/// 语音输入页面 — 说话记账
///
/// 全流程：录音 → 实时语音识别 → 文本解析 → 结果预览 → 确认保存
class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  // 录音相关
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSubscription;

  // ASR 引擎
  AsrService? _asrService;
  StreamSubscription<String>? _transcriptSubscription;

  // UI 状态
  _VoiceInputState _state = _VoiceInputState.idle;
  String _transcript = '';

  // 结果编辑表单控制器
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategoryName = '';
  String _selectedType = 'expense'; // 交易类型：expense（支出）或 income（收入）
  DateTime _selectedDate = DateTime.now(); // 交易日期
  bool _isSaving = false;

  // 录音脉冲动画
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    debugPrint('[VoiceInput] dispose');
    _audioSubscription?.cancel();
    _transcriptSubscription?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _asrService?.disconnect();
    super.dispose();
  }

  /// 开始录音
  Future<void> _startRecording() async {
    debugPrint('[VoiceInput] === _startRecording ===');

    // 检查麦克风权限
    final hasPermission = await _recorder.hasPermission();
    debugPrint('[VoiceInput] 麦克风权限: $hasPermission');
    if (!hasPermission) {
      _showSnackBar('需要麦克风权限才能录音');
      return;
    }

    // 获取 ASR 引擎实例（FutureProvider 已从数据库读取凭证构造引擎）
    final asrService = await ref.read(currentAsrEngineProvider.future);
    debugPrint('[VoiceInput] ASR 引擎: ${asrService.runtimeType}');
    _asrService = asrService;

    // 检查凭证是否已配置（根据引擎类型检查对应字段）
    final settingsDao = ref.read(settingsDaoProvider);
    if (asrService.engineId == 'dashscope') {
      final apiKey = await settingsDao.get('dashscope_api_key');
      if (apiKey == null || apiKey.isEmpty) {
        _showSnackBar('请先在设置中配置语音识别 API Key');
        return;
      }
      debugPrint('[VoiceInput] API Key 已配置');
    }

    try {
      // 连接 ASR 服务（DashScope 需要传递 apiKey；Tencent 凭证已在构造函数中）
      debugPrint('[VoiceInput] 正在连接 ASR 服务...');
      if (asrService.engineId == 'dashscope') {
        final apiKey = await settingsDao.get('dashscope_api_key');
        await asrService.connect(apiKey: apiKey ?? '', model: '');
      } else {
        await asrService.connect(apiKey: '', model: '');
      }
      debugPrint('[VoiceInput] ASR 连接成功');

      // 监听实时识别文本
      _transcriptSubscription = asrService.transcriptStream.listen(
        (text) {
          debugPrint('[VoiceInput] 收到实时识别文本: "$text"');
          if (mounted) {
            setState(() {
              _transcript = text;
            });
          }
        },
      );

      // 开始录音，以 PCM 16kHz 16bit 单声道格式录制
      debugPrint('[VoiceInput] 正在启动麦克风...');
      final audioStream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      debugPrint('[VoiceInput] 麦克风启动成功');

      // 将音频数据块实时发送给 ASR 引擎
      int chunkCount = 0;
      _audioSubscription = audioStream.listen(
        (chunk) {
          chunkCount++;
          if (chunkCount <= 3 || chunkCount % 50 == 0) {
            debugPrint('[VoiceInput] 音频块 #$chunkCount, 大小: ${chunk.length} bytes');
          }
          asrService.sendAudio(chunk);
        },
        onError: (error) {
          debugPrint('[VoiceInput] 音频流错误: $error');
          _stopRecording();
          _showSnackBar('录音出错：$error');
        },
        onDone: () {
          debugPrint('[VoiceInput] 音频流结束，共发送 $chunkCount 块');
        },
      );

      setState(() {
        _state = _VoiceInputState.recording;
        _transcript = '';
      });

      // 启动麦克风脉冲动画
      _pulseController.repeat(reverse: true);
      debugPrint('[VoiceInput] 录音已开始，状态=recording');
    } catch (e, stack) {
      debugPrint('[VoiceInput] ASR 连接/启动失败: $e\n$stack');
      // 连接或启动录音失败时回退到空闲状态
      await asrService.disconnect();
      if (mounted) {
        _showSnackBar('语音识别连接失败：$e');
      }
    }
  }

  /// 停止录音
  Future<void> _stopRecording() async {
    debugPrint('[VoiceInput] === _stopRecording ===');

    // 停止音频订阅
    debugPrint('[VoiceInput] 正在取消音频订阅...');
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    debugPrint('[VoiceInput] 音频订阅已取消');

    // 停止底层录音器
    debugPrint('[VoiceInput] 正在停止录音器...');
    try {
      await _recorder.stop();
      debugPrint('[VoiceInput] 录音器已停止');
    } catch (e) {
      debugPrint('[VoiceInput] 停止录音器出错: $e');
    }

    final asrService = _asrService;
    if (asrService == null) {
      debugPrint('[VoiceInput] _asrService 为 null，跳过 ASR 停止');
      _pulseController.stop();
      _resetToIdle();
      return;
    }

    _pulseController.stop();

    // 立即切换到解析中状态，显示加载动画，避免 UI 假死感
    setState(() {
      _state = _VoiceInputState.parsing;
    });

    try {
      // 获取最终识别文本
      debugPrint('[VoiceInput] 正在向 ASR 请求最终结果...');
      final fullText = await asrService.stop();
      debugPrint('[VoiceInput] ASR 返回原始文本: "$fullText"');
      await asrService.disconnect();

      if (!mounted) return;

      // 无识别结果时回退到空闲态
      if (fullText.isEmpty) {
        debugPrint('[VoiceInput] 识别结果为空，回退到空闲态');
        _showSnackBar('未识别到语音内容，请重试');
        _resetToIdle();
        return;
      }

      // 获取 DashScope LLM API Key 用于 AI 语义解析
      // 与语音识别（ASR）的 API Key 相互独立，需在设置中分别配置
      final settingsDao = ref.read(settingsDaoProvider);
      String? apiKey;
      try {
        apiKey = await settingsDao.get('dashscope_llm_api_key');
      } catch (_) {}

      // 获取 AI 语义解析引擎实例
      final parserService = await ref.read(currentSemanticParserProvider.future);

      // 使用 AI 语义解析（自动降级到规则引擎）
      final parser = HybridExpenseParser(
        service: parserService,
        apiKey: apiKey,
      );
      final parsed = await parser.parse(text: fullText);
      debugPrint('[VoiceInput] 解析结果: amount=${parsed.amount}, '
          'category=${parsed.categoryName}, type=${parsed.type}, '
          'date=${parsed.date}, note="${parsed.note}"');

      setState(() {
        _state = _VoiceInputState.result;
        _transcript = fullText;
        _amountController.text =
            parsed.amount?.toStringAsFixed(2) ?? '';
        _selectedCategoryName = parsed.categoryName ?? '';
        _selectedType = parsed.type ?? 'expense';
        _selectedDate = parsed.effectiveDate;
        _noteController.text = parsed.note;
      });
      debugPrint('[VoiceInput] 状态切换为 result');
    } catch (e, stack) {
      debugPrint('[VoiceInput] 停止录音/解析出错: $e\n$stack');
      if (!mounted) return;
      _showSnackBar('语音识别失败：$e');
      _resetToIdle();
    }
  }

  /// 重置到初始状态
  void _resetToIdle() {
    debugPrint('[VoiceInput] _resetToIdle');
    _asrService?.disconnect();
    _asrService = null;
    _transcript = '';
    _amountController.clear();
    _noteController.clear();
    _selectedCategoryName = '';
    _selectedType = 'expense';
    _selectedDate = DateTime.now();
    _pulseController.reset();
    setState(() {
      _state = _VoiceInputState.idle;
    });
  }

  /// 确认创建交易记录
  Future<void> _confirmTransaction() async {
    debugPrint('[VoiceInput] _confirmTransaction');
    if (_isSaving) return;

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnackBar('请输入有效金额');
      return;
    }

    if (_selectedCategoryName.isEmpty) {
      _showSnackBar('请选择分类');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 根据分类名称查找分类 ID
      final categories = await ref.read(allCategoriesProvider.future);
      final selectedCategory = categories.firstWhere(
        (c) => c.name == _selectedCategoryName,
        orElse: () => categories.first,
      );
      debugPrint('[VoiceInput] 保存交易: amount=$amount, '
          'category=${selectedCategory.name}, type=$_selectedType, '
          'date=$_selectedDate, note=${_noteController.text}');

      // 使用解析出的交易日期（如果用户未修改则保持 AI 解析结果）
      final now = DateTime.now();
      final transactionDate = _selectedDate;

      // 将交易记录写入数据库
      await ref.read(transactionDaoProvider).insert(
        TransactionsTableCompanion.insert(
          amount: amount,
          categoryId: selectedCategory.id,
          type: _selectedType,
          date: transactionDate,
          note: Value(_noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim()),
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (!mounted) return;
      debugPrint('[VoiceInput] 交易保存成功');
      _showSnackBar('记账成功');
      context.pop();
    } catch (e, stack) {
      debugPrint('[VoiceInput] 保存失败: $e\n$stack');
      if (!mounted) return;
      _showSnackBar('保存失败：$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 显示提示消息
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_state) {
            _VoiceInputState.idle => _buildIdleLayout(context),
            _VoiceInputState.recording => _buildRecordingLayout(context),
            _VoiceInputState.parsing => _buildParsingLayout(context),
            _VoiceInputState.result => _buildResultLayout(context),
          },
        ),
      ),
    );
  }

  // ─── 关闭按钮 ─────────────────────────────────

  /// 左上角关闭按钮，40×40 毛玻璃圆，x 图标
  /// 录音中先停止再关闭
  Widget _buildCloseButton() {
    return Tooltip(
      message: '关闭',
      child: GestureDetector(
        onTap: () {
          if (_state == _VoiceInputState.recording) {
            _stopRecording();
          }
          context.pop();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0x26FFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsLight.x,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── 语音波形中心区域 ──────────────────────────

  /// 同心圆波形 + 麦克风图标，[animated] 控制录制脉冲动画
  Widget _buildVoiceWaveform({required bool animated}) {
    final waveform = Stack(
      alignment: Alignment.center,
      children: [
        // 外圈 180
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x14FFFFFF),
              width: 1,
            ),
          ),
        ),
        // 中圈 160
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x1FFFFFFF),
              width: 1.5,
            ),
          ),
        ),
        // 内圈 130
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x26FFFFFF),
              width: 1.5,
            ),
          ),
        ),
        // 麦克风图标
        const Icon(
          PhosphorIconsLight.microphone,
          color: Colors.white,
          size: 48,
        ),
      ],
    );

    if (!animated) return waveform;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + _pulseController.value * 0.1;
        return Transform.scale(scale: scale, child: child);
      },
      child: waveform,
    );
  }

  /// 语音中心区域容器（220×220 毛玻璃 + 波形 + 状态文字）
  Widget _buildVoiceCenter({
    required bool animated,
    required String statusText,
    String? subText,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        // 220×220 毛玻璃容器（可点击触发录音）
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(110),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(110),
                  border: Border.all(
                    color: const Color(0x40FFFFFF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: _buildVoiceWaveform(animated: animated),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 状态文字
        Text(
          statusText,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (subText != null) ...[
          const SizedBox(height: 4),
          Text(
            subText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0x99FFFFFF),
            ),
          ),
        ],
      ],
    );
  }

  // ─── 识别结果玻璃卡片 ─────────────────────────

  /// 识别结果卡片，[text] 为空时显示占位提示
  Widget _buildRecognizedTextGlass({required String text, bool showLabel = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0x26FFFFFF),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '识别结果',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text.isEmpty ? '等待语音输入...' : text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 操作按钮 ─────────────────────────────────

  /// 底部操作按钮行：取消 + 确认添加
  Widget _buildActionButtons({required bool confirmEnabled}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 取消按钮
        GestureDetector(
          onTap: _state == _VoiceInputState.recording ? _stopRecording : _resetToIdle,
          child: Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0x33FFFFFF),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                '取消',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xB3FFFFFF),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 确认添加按钮
        GestureDetector(
          onTap: confirmEnabled && !_isSaving ? _confirmTransaction : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 140,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x40FFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0x4DFFFFFF),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '✓ 确认添加',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 三态布局 ─────────────────────────────────

  /// 初始空闲态：波形 + "点击开始录音" + 空卡片 + 禁用的确认
  Widget _buildIdleLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _buildCloseButton(),
        ),
        const Spacer(),
        _buildVoiceCenter(
          animated: false,
          statusText: '点击开始录音',
          onTap: _startRecording,
        ),
        const SizedBox(height: 12),
        _buildRecognizedTextGlass(text: ''),
        const SizedBox(height: 12),
        _buildActionButtons(confirmEnabled: false),
        const Spacer(),
      ],
    );
  }

  /// 录音中：脉冲波形 + "正在聆听..." + 实时识别文本
  Widget _buildRecordingLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _buildCloseButton(),
        ),
        const Spacer(),
        _buildVoiceCenter(
          animated: true,
          statusText: '正在聆听...',
          subText: '说出你的记账内容',
          onTap: _stopRecording,
        ),
        const SizedBox(height: 12),
        _buildRecognizedTextGlass(
          text: _transcript.isEmpty ? '正在听...' : _transcript,
          showLabel: true,
        ),
        const SizedBox(height: 12),
        _buildActionButtons(confirmEnabled: false),
        const Spacer(),
      ],
    );
  }

  /// 解析中态：脉冲波形停止 + "正在分析..." + 识别文本 + 旋转加载指示器
  ///
  /// 此状态在停止录音后立即显示，避免用户在等待 AI 解析时看到静止界面产生假死感。
  /// AI 解析完成后自动切换到 result 态或空闲态（出错时）。
  Widget _buildParsingLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 左上角关闭按钮
        Align(
          alignment: Alignment.centerLeft,
          child: _buildCloseButton(),
        ),
        const Spacer(),
        // 波形中心（无动画，不响应点击）
        _buildVoiceCenter(
          animated: false,
          statusText: '正在分析...',
          subText: 'AI 正在解析语音内容',
        ),
        const SizedBox(height: 24),
        // 旋转加载指示器
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 24),
        // 显示识别到的原始文本
        _buildRecognizedTextGlass(
          text: _transcript.isEmpty ? '正在获取识别结果...' : _transcript,
          showLabel: true,
        ),
        const Spacer(),
      ],
    );
  }

  /// 结果态：精简波形 + 识别文本 + 编辑表单 + 操作按钮
  Widget _buildResultLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 关闭按钮（左对齐）
          Align(
            alignment: Alignment.centerLeft,
            child: _buildCloseButton(),
          ),
          const SizedBox(height: 12),
          _buildVoiceCenter(
            animated: false,
            statusText: '识别完成',
          ),
          const SizedBox(height: 12),
          // 识别结果
          _buildRecognizedTextGlass(text: _transcript, showLabel: true),
          const SizedBox(height: 20),
          // 编辑表单
          _buildEditForm(context),
          const SizedBox(height: 20),
          // 操作按钮
          _buildActionButtons(confirmEnabled: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── 编辑表单（结果态） ────────────────────────

  /// 解析结果编辑表单：金额 + 类型 + 分类 + 日期 + 备注
  Widget _buildEditForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 金额输入
        _buildFormLabel(context, '金额'),
        const SizedBox(height: 8),
        _buildAmountField(context),
        const SizedBox(height: 20),
        // 交易类型（支出/收入）
        _buildFormLabel(context, '类型'),
        const SizedBox(height: 8),
        _buildTypeToggle(context),
        const SizedBox(height: 20),
        // 分类选择
        _buildFormLabel(context, '分类'),
        const SizedBox(height: 8),
        _buildCategoryDropdown(context),
        const SizedBox(height: 20),
        // 日期选择
        _buildFormLabel(context, '日期'),
        const SizedBox(height: 8),
        _buildDateField(context),
        const SizedBox(height: 20),
        // 备注输入
        _buildFormLabel(context, '备注'),
        const SizedBox(height: 8),
        _buildNoteField(context),
      ],
    );
  }

  /// 交易类型切换按钮（支出/收入）
  Widget _buildTypeToggle(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.glassFillStrong(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.glassStroke(context)),
      ),
      child: Row(
        children: [
          // 支出按钮
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = 'expense'),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedType == 'expense'
                      ? const Color(0x40FFFFFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(4),
                child: Text(
                  '支出',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedType == 'expense'
                        ? Colors.white
                        : const Color(0x99FFFFFF),
                  ),
                ),
              ),
            ),
          ),
          // 收入按钮
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = 'income'),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedType == 'income'
                      ? const Color(0x40FFFFFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(4),
                child: Text(
                  '收入',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedType == 'income'
                        ? Colors.white
                        : const Color(0x99FFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 日期选择器
  Widget _buildDateField(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 弹出日期选择对话框
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: Colors.white.withValues(alpha: 0.6),
                  onPrimary: Colors.black,
                  surface: const Color(0xFF2A2A2A),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && mounted) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.glassFillStrong(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.glassStroke(context)),
        ),
        child: Row(
          children: [
            Text(
              DateFormat('yyyy-MM-dd').format(_selectedDate),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textOnSurface(context),
              ),
            ),
            const Spacer(),
            Icon(
              PhosphorIconsLight.calendarBlank,
              color: AppTheme.textOnSurfaceTertiary(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 编辑表单标签文字
  Widget _buildFormLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textOnSurfaceSecondary(context),
      ),
    );
  }

  /// 金额输入框
  Widget _buildAmountField(BuildContext context) {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textOnSurface(context),
      ),
      decoration: InputDecoration(
        prefixText: '¥ ',
        prefixStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textOnSurface(context),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassStroke(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassStroke(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassFillAccent(context)),
        ),
        filled: true,
        fillColor: AppTheme.glassFillStrong(context),
      ),
    );
  }

  /// 备注输入框
  Widget _buildNoteField(BuildContext context) {
    return TextField(
      controller: _noteController,
      style: TextStyle(
        fontSize: 16,
        color: AppTheme.textOnSurface(context),
      ),
      decoration: InputDecoration(
        hintText: '添加备注...',
        hintStyle: TextStyle(
          color: AppTheme.textOnSurfaceTertiary(context),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassStroke(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassStroke(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.glassFillAccent(context)),
        ),
        filled: true,
        fillColor: AppTheme.glassFillStrong(context),
      ),
    );
  }

  /// 分类下拉选择器，从 allCategoriesProvider 获取数据
  Widget _buildCategoryDropdown(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        // 过滤出支出分类
        final expenseCategories =
            categories.where((c) => c.type == 'expense').toList();

        // 如果当前选中项不在列表中则重置
        if (_selectedCategoryName.isNotEmpty &&
            !expenseCategories.any((c) => c.name == _selectedCategoryName)) {
          _selectedCategoryName = '';
        }

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.glassFillStrong(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.glassStroke(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryName.isEmpty
                  ? null
                  : _selectedCategoryName,
              isExpanded: true,
              hint: Text(
                '选择分类',
                style: TextStyle(
                  color: AppTheme.textOnSurfaceTertiary(context),
                ),
              ),
              dropdownColor: const Color(0xFF2A2A2A),
              items: expenseCategories.map((c) {
                return DropdownMenuItem<String>(
                  value: c.name,
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: _parseHexColor(c.color),
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: TextStyle(
                          color: AppTheme.textOnSurface(context),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategoryName = value);
                }
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox(height: 48),
    );
  }

  /// 将形如 "#A3B59A" 的十六进制颜色字符串转为 Color 对象
  Color _parseHexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    final full = h.length == 6 ? 'FF$h' : h;
    return Color(int.parse(full, radix: 16));
  }
}
