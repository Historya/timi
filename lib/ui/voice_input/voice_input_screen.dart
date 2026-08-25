// 语音输入页面 — 按住录音，松开结束，识别账目后确认添加

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:record/record.dart';
import 'package:timi/core/constants/transaction_type.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/data/database/app_database.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/services/asr_service.dart';
import 'package:timi/services/expense_parser.dart';
import 'package:timi/services/semantic_parser.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

/// 语音输入页面状态枚举
enum _VoiceInputState {
  /// 初始状态，等待用户按住麦克风按钮
  idle,

  /// 正在录音中（用户按住按钮）
  recording,

  /// 停止录音后正在 AI 语义解析中
  parsing,

  /// 识别完成，显示结果及"确定添加账目"按钮
  result,
}

/// 语音输入页面 — 说话记账
///
/// 交互流程：
/// 1. 用户按住麦克风按钮 → 开始录音，显示频率波纹动画 + 实时识别文本
/// 2. 用户松开按钮 → 录音结束，AI 语义解析
/// 3. 解析成功 → 显示"确定添加账目"按钮
///
/// 全流程：按住录音 → 实时语音识别 → 松开 → 文本解析 → 预览 → 确认保存
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
  StreamSubscription<AsrConnectionState>? _asrConnectionSubscription;

  // 首块音频数据保护定时器（录音启动后若迟迟无数据则主动停止）
  Timer? _firstChunkTimer;

  // UI 状态
  _VoiceInputState _state = _VoiceInputState.idle;
  String _transcript = '';

  // 多账目解析结果（同类合并后），单笔时长度为 1
  List<ParsedExpense> _parsedExpenses = const [];
  int _selectedExpenseIndex = 0;

  // 结果编辑表单控制器
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategoryName = '';
  String _selectedType = 'expense';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  /// 标记当前选中的分类是否为 AI 推荐的新分类（数据库中不存在）
  /// 为 true 时，确认添加账目后自动创建该分类
  bool _isNewCategory = false;

  // 录音脉冲动画 — 驱动波形条动画
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
    _asrConnectionSubscription?.cancel();
    _firstChunkTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _asrService?.disconnect();
    super.dispose();
  }

  // ─── 录音控制 ─────────────────────────────────

  /// 按下麦克风按钮时调用 — 开始录音
  Future<void> _startRecording() async {
    debugPrint('[VoiceInput] === _startRecording ===');
    final l10n = AppLocalizations.of(context);

    // 检查麦克风权限
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      TopNotification.show(
        context,
        message: l10n.micPermissionRequired,
        type: TopNotificationType.warning,
      );
      return;
    }

    // 获取 ASR 引擎实例（FutureProvider 已从数据库读取凭证构造引擎）
    final asrService = await ref.read(currentAsrEngineProvider.future);
    debugPrint('[VoiceInput] ASR 引擎: ${asrService.runtimeType}');
    _asrService = asrService;

    // 检查并获取 API Key（只读取一次数据库）
    String? apiKey;
    if (asrService.engineId == 'dashscope') {
      final settingsDao = ref.read(settingsDaoProvider);
      apiKey = await settingsDao.get('dashscope_api_key');
      if (apiKey == null || apiKey.isEmpty) {
        if (!mounted) return;
        TopNotification.show(
          context,
          message: l10n.asrConfigRequired,
          type: TopNotificationType.warning,
        );
        return;
      }
    }

    try {
      // 连接 ASR 服务
      await asrService.connect(apiKey: apiKey ?? '', model: '');
      debugPrint('[VoiceInput] ASR 连接成功');

      // 监听实时识别文本
      _transcriptSubscription = asrService.transcriptStream.listen((text) {
        if (mounted) {
          setState(() {
            _transcript = text;
          });
        }
      });

      // 监听 ASR 连接状态，出错时自动停止录音并提示
      _asrConnectionSubscription?.cancel();
      _asrConnectionSubscription =
          asrService.connectionStateStream.listen((state) {
        if (state == AsrConnectionState.error &&
            mounted &&
            _state == _VoiceInputState.recording) {
          debugPrint('[VoiceInput] ASR 连接出错，自动停止录音');
          _stopRecordingForAsrError();
        }
      });

      // 开始录音，以 PCM 16kHz 16bit 单声道格式录制
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
      bool gotFirstChunk = false;

      // 首块数据保护：若 3 秒内无任何音频数据（麦克风异常/占用/静默无输出），
      // 主动停止，避免等服务端 15 秒超时报"未发送音频数据"
      _firstChunkTimer?.cancel();
      _firstChunkTimer = Timer(const Duration(seconds: 3), () {
        if (!gotFirstChunk &&
            mounted &&
            _state == _VoiceInputState.recording) {
          debugPrint('[VoiceInput] 3 秒内未收到音频数据，主动停止');
          _audioSubscription?.cancel();
          _audioSubscription = null;
          unawaited(_recorder.stop().catchError((_) => null));
          _pulseController.stop();
          TopNotification.show(
            context,
            message: l10n.noSpeechDetected,
            type: TopNotificationType.warning,
          );
          _resetToIdle();
        }
      });

      _audioSubscription = audioStream.listen(
        (chunk) {
          if (!gotFirstChunk) {
            gotFirstChunk = true;
            _firstChunkTimer?.cancel();
            _firstChunkTimer = null;
          }
          chunkCount++;
          asrService.sendAudio(chunk);
        },
        onError: (error) {
          debugPrint('[VoiceInput] 音频流错误: $error');
          _stopRecording();
          if (!mounted) return;
          TopNotification.show(
            context,
            message: l10n.recordingError(error.toString()),
            type: TopNotificationType.error,
          );
        },
        onDone: () {
          debugPrint('[VoiceInput] 音频流结束，共发送 $chunkCount 块');
        },
      );

      setState(() {
        _state = _VoiceInputState.recording;
        _transcript = '';
      });

      // 启动波形条动画
      _pulseController.repeat(reverse: true);
      debugPrint('[VoiceInput] 录音已开始，状态=recording');
    } catch (e, stack) {
      debugPrint('[VoiceInput] ASR 连接/启动失败: $e\n$stack');
      await asrService.disconnect();
      if (mounted) {
        TopNotification.show(
          context,
          message: l10n.speechRecognitionFailed(e.toString()),
          type: TopNotificationType.error,
        );
      }
    }
  }

  /// 松开麦克风按钮时调用 — 停止录音
  Future<void> _stopRecording() async {
    debugPrint('[VoiceInput] === _stopRecording ===');
    final l10n = AppLocalizations.of(context);

    // 如果不在录音状态则忽略
    if (_state != _VoiceInputState.recording) return;

    // 取消首块数据保护定时器
    _firstChunkTimer?.cancel();
    _firstChunkTimer = null;

    // 停止音频订阅
    await _audioSubscription?.cancel();
    _audioSubscription = null;

    // 停止底层录音器
    try {
      await _recorder.stop();
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

    // 立即切换到解析中状态
    setState(() {
      _state = _VoiceInputState.parsing;
    });

    try {
      // 获取最终识别文本
      final fullText = await asrService.stop();
      debugPrint('[VoiceInput] ASR 返回原始文本: "$fullText"');
      await asrService.disconnect();

      if (!mounted) return;

      // 无识别结果时回退到空闲态
      if (fullText.isEmpty) {
        TopNotification.show(
          context,
          message: l10n.noSpeechDetected,
          type: TopNotificationType.warning,
        );
        _resetToIdle();
        return;
      }

      // 获取 DashScope LLM API Key 用于 AI 语义解析
      final settingsDao = ref.read(settingsDaoProvider);
      String? apiKey;
      try {
        apiKey = await settingsDao.get('dashscope_llm_api_key');
      } catch (_) {}

      // 获取 AI 语义解析引擎实例
      final parserService = await ref.read(
        currentSemanticParserProvider.future,
      );

      // 使用 AI 语义解析（自动降级到规则引擎）
      final parser = HybridExpenseParser(
        service: parserService,
        apiKey: apiKey,
      );
      final parsedList = await parser.parse(text: fullText);
      debugPrint('[VoiceInput] 解析出 ${parsedList.length} 笔账目');

      // 仅保留有效金额的账目
      final validList = parsedList.where((e) => e.hasValidAmount).toList();
      if (validList.isEmpty) {
        debugPrint('[VoiceInput] 无有效金额账目，回到空闲态');
        if (!mounted) return;
        TopNotification.show(
          context,
          message: l10n.noSpeechDetected,
          type: TopNotificationType.warning,
        );
        _resetToIdle();
        return;
      }

      // 同类合并，减少确认负担（如"午饭25、晚饭30"合并为餐饮55）
      final mergedList = ExpenseParser.mergeSameCategory(validList);
      debugPrint('[VoiceInput] 同类合并后 ${mergedList.length} 笔账目');
      for (final e in mergedList) {
        debugPrint(
          '[VoiceInput]   账目: amount=${e.amount}, '
          'category=${e.categoryName}, type=${e.type}, '
          'date=${e.date}, note="${e.note}"',
        );
      }

      // 填充第一笔账目的表单，后续可在卡片间切换
      _parsedExpenses = mergedList;
      _syncFormFromIndex(0);

      setState(() {
        _state = _VoiceInputState.result;
        _transcript = fullText;
      });
      debugPrint(
        '[VoiceInput] 状态切换为 result, '
        '账目数=${mergedList.length}',
      );
    } catch (e, stack) {
      debugPrint('[VoiceInput] 停止录音/解析出错: $e\n$stack');
      if (!mounted) return;
      TopNotification.show(
        context,
        message: l10n.speechRecognitionFailed(e.toString()),
        type: TopNotificationType.error,
      );
      _resetToIdle();
    }
  }

  /// ASR 服务端出错时自动停止录音（如"15 秒未发送音频数据"等 task-failed）
  ///
  /// 直接停止录音器与音频发送，提示错误后回到空闲态，不进入解析流程。
  void _stopRecordingForAsrError() {
    final l10n = AppLocalizations.of(context);
    _firstChunkTimer?.cancel();
    _firstChunkTimer = null;

    // 停止音频订阅与底层录音器，避免继续向失效连接发送数据
    _audioSubscription?.cancel();
    _audioSubscription = null;
    unawaited(_recorder.stop().catchError((_) => null));
    _pulseController.stop();

    if (!mounted) return;
    TopNotification.show(
      context,
      message: l10n.speechRecognitionFailed('ASR connection error'),
      type: TopNotificationType.error,
    );
    _resetToIdle();
  }

  /// 将指定下标的账目填充到编辑表单，并切换当前选中卡片
  void _syncFormFromIndex(int index) {
    if (index < 0 || index >= _parsedExpenses.length) return;
    final item = _parsedExpenses[index];
    final name = item.categoryName ?? '';
    // 判断分类是否已存在（用于"新分类"标记）
    final categories = ref.read(allCategoriesProvider).value ?? const [];
    setState(() {
      _selectedExpenseIndex = index;
      _amountController.text = item.amount?.toStringAsFixed(2) ?? '';
      _selectedCategoryName = name;
      _selectedType = item.type ?? 'expense';
      _selectedDate = item.date ?? DateTime.now();
      _noteController.text = item.note;
      _isNewCategory =
          name.isNotEmpty && !categories.any((c) => c.name == name);
    });
  }

  /// 当前选中卡片下标的有效金额（表单值，未编辑项用解析值）
  double? _effectiveAmount(int index) {
    if (index == _selectedExpenseIndex) {
      return double.tryParse(_amountController.text.trim());
    }
    return _parsedExpenses[index].amount;
  }

  /// 当前选中卡片下标的有效分类名
  String _effectiveCategoryName(int index) {
    if (index == _selectedExpenseIndex) {
      return _selectedCategoryName;
    }
    return _parsedExpenses[index].categoryName ?? '';
  }

  /// 当前选中卡片下标的有效交易类型
  String _effectiveType(int index) {
    if (index == _selectedExpenseIndex) {
      return _selectedType;
    }
    return _parsedExpenses[index].type ?? 'expense';
  }

  /// 当前选中卡片下标的有效交易日期
  DateTime _effectiveDate(int index) {
    if (index == _selectedExpenseIndex) {
      return _selectedDate;
    }
    return _parsedExpenses[index].date ?? _selectedDate;
  }

  /// 当前选中卡片下标的有效备注
  String _effectiveNote(int index) {
    if (index == _selectedExpenseIndex) {
      return _noteController.text.trim();
    }
    return _parsedExpenses[index].note;
  }

  /// 重置到初始状态
  void _resetToIdle() {
    _asrService?.disconnect();
    _asrService = null;
    _transcript = '';
    _parsedExpenses = const [];
    _selectedExpenseIndex = 0;
    _amountController.clear();
    _noteController.clear();
    _selectedCategoryName = '';
    _selectedType = 'expense';
    _selectedDate = DateTime.now();
    _isNewCategory = false;
    _pulseController.reset();
    setState(() {
      _state = _VoiceInputState.idle;
    });
  }

  /// 确认创建交易记录（多笔账目时批量保存）
  /// 确认当前选中卡片 — 保存该笔账目并从卡片列表移除
  Future<void> _confirmTransaction() => _confirmSingleExpense(_selectedExpenseIndex);

  /// 单独确认单张账目卡片 — 保存该笔并从卡片列表移除
  Future<void> _confirmSingleExpense(int index) async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context);

    final amount = _effectiveAmount(index);
    if (amount == null || amount <= 0) {
      _syncFormFromIndex(index);
      TopNotification.show(
        context,
        message: l10n.enterValidAmount,
        type: TopNotificationType.warning,
      );
      return;
    }
    final categoryName = _effectiveCategoryName(index);
    if (categoryName.isEmpty) {
      _syncFormFromIndex(index);
      TopNotification.show(
        context,
        message: l10n.pleaseSelectCategory,
        type: TopNotificationType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _saveTransaction(
        amount: amount,
        categoryName: categoryName,
        type: _effectiveType(index),
        date: _effectiveDate(index),
        note: _effectiveNote(index),
      );

      if (!mounted) return;

      // 从卡片列表移除已确认项
      _removeExpenseFromList(index);

      debugPrint(
        '[VoiceInput] 单笔确认成功，剩余 ${_parsedExpenses.length} 笔',
      );
      if (!mounted) return;

      if (_parsedExpenses.isEmpty) {
        // 全部确认完成，返回上一页
        TopNotification.show(
          context,
          message: l10n.recordingSuccess,
          type: TopNotificationType.success,
        );
        context.pop();
      } else {
        TopNotification.show(
          context,
          message: l10n.recordingSuccess,
          type: TopNotificationType.success,
        );
      }
    } catch (e, stack) {
      debugPrint('[VoiceInput] 单笔保存失败: $e\n$stack');
      if (!mounted) return;
      TopNotification.show(
        context,
        message: l10n.saveFailed(e.toString()),
        type: TopNotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 取消单张账目卡片 — 不保存，仅从卡片列表移除
  void _removeExpenseCard(int index) {
    if (_isSaving) return;
    _removeExpenseFromList(index);
    // 全部移除后回到空闲态
    if (_parsedExpenses.isEmpty) {
      _resetToIdle();
    }
  }

  /// 从卡片列表移除指定下标的账目，并重排选中索引、同步表单
  void _removeExpenseFromList(int index) {
    if (_parsedExpenses.isEmpty ||
        index < 0 ||
        index >= _parsedExpenses.length) {
      return;
    }
    final next = List<ParsedExpense>.of(_parsedExpenses)..removeAt(index);
    setState(() {
      _parsedExpenses = next;
      if (next.isEmpty) {
        _selectedExpenseIndex = 0;
      } else if (_selectedExpenseIndex >= next.length) {
        _selectedExpenseIndex = next.length - 1;
      } else if (index < _selectedExpenseIndex) {
        _selectedExpenseIndex--;
      }
    });

    // 还有剩余账目时，将表单同步到当前选中卡片
    if (next.isNotEmpty) {
      _syncFormFromIndex(_selectedExpenseIndex);
    }
  }

  /// 保存单笔交易（查找/创建分类 + 插入交易记录）
  Future<void> _saveTransaction({
    required double amount,
    required String categoryName,
    required String type,
    required DateTime date,
    required String note,
  }) async {
    final now = DateTime.now();
    final categoryDao = ref.read(categoryDaoProvider);
    final transactionDao = ref.read(transactionDaoProvider);
    final categories = await ref.read(allCategoriesProvider.future);

    // 查找已有分类，不存在则自动创建
    int categoryId;
    final existing = categories.where((c) => c.name == categoryName);
    if (existing.isNotEmpty) {
      categoryId = existing.first.id;
    } else {
      debugPrint('[VoiceInput] 自动创建新分类: $categoryName');
      categoryId = await categoryDao.insert(
        CategoriesTableCompanion(
          name: Value(categoryName),
          icon: const Value('dotsThree'),
          color: const Value('#69DB7C'),
          type: Value(type),
          sortOrder: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }

    await transactionDao.insert(
      TransactionsTableCompanion.insert(
        amount: amount,
        categoryId: categoryId,
        type: type,
        date: date,
        note: Value(note.isEmpty ? null : note),
        createdAt: now,
        updatedAt: now,
      ),
    );
    debugPrint(
      '[VoiceInput] 已保存: amount=$amount, category=$categoryName, '
      'type=$type, date=$date, note="$note"',
    );
  }

  // ─── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 语音输入页面跟随当前主题
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 关闭按钮
              Align(
                alignment: Alignment.centerLeft,
                child: _buildCloseButton(),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: switch (_state) {
                      _VoiceInputState.idle => _buildIdleLayout(context),
                      _VoiceInputState.recording => _buildRecordingLayout(
                        context,
                      ),
                      _VoiceInputState.parsing => _buildParsingLayout(context),
                      _VoiceInputState.result => _buildResultLayout(context),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 关闭按钮 ─────────────────────────────────

  /// 左上角关闭按钮，40×40 毛玻璃圆，x 图标
  Widget _buildCloseButton() {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.close,
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
              decoration: BoxDecoration(
                color: AppTheme.glassFillStrong(context).withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsLight.x,
                color: AppTheme.textOnSurface(context),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── 频率波纹动画 ─────────────────────────────

  /// 频率条波形动画，根据录音状态显示不同的动画效果
  Widget _buildWaveformAnimation({required bool animated}) {
    // 波形条颜色跟随当前主题
    final barColor = AppTheme.textOnSurface(context).withValues(alpha: 0.24);
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 130),
          painter: _WaveformBarPainter(
            // 录音中：利用脉冲值驱动条高变化产生波纹动效
            // 空闲/结果态：静止显示低矮条
            animationValue: animated ? _pulseController.value : 0.0,
            barColor: barColor,
          ),
        );
      },
    );
  }

  /// 波纹动画区域容器
  Widget _buildWaveformArea({
    required bool animated,
    required String statusText,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 130,
          child: _buildWaveformAnimation(animated: animated),
        ),
        const SizedBox(height: 16),
        // 状态文字
        Text(
          statusText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: AppTheme.textOnSurfaceTertiary(context),
          ),
        ),
      ],
    );
  }

  // ─── 识别文本毛玻璃卡片 ─────────────────────────

  /// 语音识别文本展示区域，毛玻璃卡片样式
  Widget _buildRecognitionCard({required String text, bool showLabel = false}) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.glassFill(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassStroke(context), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showLabel)
                Text(
                  l10n.recognitionResult,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppTheme.textOnSurface(
                      context,
                    ).withValues(alpha: 0.38),
                  ),
                ),
              if (showLabel) const SizedBox(height: 10),
              Text(
                text.isEmpty ? l10n.waitingForSpeech : text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textOnSurface(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 麦克风按钮（按住录音） ─────────────────────

  /// 大麦克风按钮 — 用户需要按住此按钮进行录音，松开即结束
  ///
  /// 使用 [Listener] 而非 [GestureDetector] 监听原始指针事件，
  /// 避免 GestureDetector 的 tap 手势仲裁超时（~500ms）导致
  /// 长按时自动取消。
  ///
  /// 视觉样式根据录音状态切换：空闲态半透明，录音中加强填充。
  Widget _buildMicButton() {
    final l10n = AppLocalizations.of(context);
    final isRecording = _state == _VoiceInputState.recording;
    return Listener(
      // 按下 → 开始录音
      onPointerDown: (_) => _startRecording(),
      // 松开 → 停止录音
      onPointerUp: (_) => _stopRecording(),
      onPointerCancel: (_) => _stopRecording(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 80×80 毛玻璃麦克风按钮
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  // 录音中加强填充和边框，表示按下状态
                  color: isRecording
                      ? AppTheme.glassFillAccent(context)
                      : AppTheme.glassFillStrong(context),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: isRecording
                        ? AppTheme.glassStroke(context).withValues(alpha: 0.8)
                        : AppTheme.glassStroke(context),
                    width: isRecording ? 1.5 : 1,
                  ),
                ),
                child: Icon(
                  PhosphorIconsFill.microphone,
                  color: AppTheme.textOnSurface(context),
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 状态提示文字
          Text(
            isRecording ? l10n.releaseToStop : l10n.holdToTalk,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isRecording ? FontWeight.w500 : FontWeight.normal,
              color: isRecording
                  ? AppTheme.textOnSurfaceSecondary(context)
                  : AppTheme.textOnSurfaceTertiary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 确定添加账目按钮 ──────────────────────────

  /// 确认添加账目按钮 — 用户松开按钮后，识别到账目时显示
  Widget _buildConfirmButton() {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: _isSaving ? null : _confirmTransaction,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.glassFillStrong(context),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppTheme.glassStroke(context),
                width: 1,
              ),
            ),
            child: Center(
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppTheme.textOnSurface(context),
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsLight.check,
                          color: AppTheme.textOnSurface(context),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.confirmTransaction,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textOnSurface(context),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── 四态布局 ─────────────────────────────────

  /// 初始空闲态：波纹静止 + 空识别卡片 + 麦克风按钮（"按住说话"）
  Widget _buildIdleLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const Spacer(flex: 2),
        // 波纹动画（静止）
        _buildWaveformArea(animated: false, statusText: l10n.ready),
        const SizedBox(height: 16),
        // 识别文本卡片（空）
        _buildRecognitionCard(text: ''),
        const Spacer(flex: 2),
        // 麦克风按钮 — 按住录音
        _buildMicButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 录音中：波纹动画 + 实时识别文本 + 麦克风按钮（按压态）
  Widget _buildRecordingLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const Spacer(flex: 2),
        // 波纹动画（动态）
        _buildWaveformArea(animated: true, statusText: l10n.listening),
        const SizedBox(height: 16),
        // 实时识别文本
        _buildRecognitionCard(
          text: _transcript.isEmpty ? l10n.listening : _transcript,
          showLabel: true,
        ),
        const Spacer(flex: 2),
        // 麦克风按钮 — 按住录音（会自动匹配按压态样式）
        _buildMicButton(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 解析中态：波纹停止 + 实时文本 + 加载指示器
  Widget _buildParsingLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const Spacer(flex: 2),
        // 波纹动画（停止）
        _buildWaveformArea(animated: false, statusText: l10n.analyzing),
        const SizedBox(height: 16),
        // 识别文本
        _buildRecognitionCard(
          text: _transcript.isEmpty ? l10n.gettingRecognitionResult : _transcript,
          showLabel: true,
        ),
        const SizedBox(height: 16),
        // 加载指示器
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: AppTheme.textOnSurface(context),
            strokeWidth: 2.5,
          ),
        ),
        const Spacer(flex: 2),
        // 占位，保持底部一致
        const SizedBox(height: 80),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 结果态：最终文本 + 编辑表单 + 确认添加 + 取消按钮
  ///
  /// 多笔账目时顶部显示横向卡片选择器（类似 Android 前台任务卡片），
  /// 点击卡片切换当前编辑的账单；单笔时保持原有单一表单体验。
  Widget _buildResultLayout(BuildContext context) {
    final isMulti = _parsedExpenses.length > 1;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (isMulti) ...[
            _buildExpenseCardList(context),
            const SizedBox(height: 20),
          ],
          // 编辑表单（当前选中卡片）
          _buildEditForm(context),
          const SizedBox(height: 24),
          // 底部操作行：确认添加账目（左）+ 取消按钮（右），横向并列
          Row(
            children: [
              Expanded(child: _buildConfirmButton()),
              const SizedBox(width: 12),
              Expanded(child: _buildCancelButton()),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── 多账目卡片选择器 ──────────────────────────

  /// 横向排列的账目卡片列表（仅多笔账目时显示）
  Widget _buildExpenseCardList(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _parsedExpenses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _buildExpenseCard(context, index),
      ),
    );
  }

  /// 单张账目卡片 — 展示分类、金额、备注，点击选中
  Widget _buildExpenseCard(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context);
    final item = _parsedExpenses[index];
    final isSelected = index == _selectedExpenseIndex;
    final categoryName = item.categoryName ?? l10n.uncategorized;
    final amount = item.amount?.toStringAsFixed(2) ?? '--';
    final note = item.note.isEmpty ? '' : item.note;

    return GestureDetector(
      onTap: () => _syncFormFromIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.glassFillAccent(context)
              : AppTheme.glassFill(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentBlue.withValues(alpha: 0.8)
                : AppTheme.glassStroke(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 序号 + 分类名 + 单独确认按钮
            Row(
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textOnSurface(context).withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
                ),
                // 取消该卡片按钮：不保存，仅从列表移除
                GestureDetector(
                  onTap: () => _removeExpenseCard(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.glassFillStrong(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.glassStroke(context),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      PhosphorIconsLight.x,
                      size: 12,
                      color: AppTheme.textOnSurfaceSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 单独确认按钮：保存该笔并从列表移除
                GestureDetector(
                  onTap: () => _confirmSingleExpense(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentBlue.withValues(alpha: 0.15)
                          : AppTheme.glassFillStrong(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentBlue.withValues(alpha: 0.6)
                            : AppTheme.glassStroke(context),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      PhosphorIconsLight.check,
                      size: 12,
                      color: isSelected
                          ? AppTheme.accentBlue
                          : AppTheme.textOnSurfaceSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 金额
            Text(
              '¥ $amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppTheme.accentBlue
                    : AppTheme.textOnSurface(context),
              ),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textOnSurfaceTertiary(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 取消按钮 — 点击后回到空闲态，重新显示麦克风按钮
  ///
  /// 与确认按钮横向并列，毛玻璃样式，视觉对称
  Widget _buildCancelButton() {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: _resetToIdle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.glassFill(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.glassStroke(context),
                width: 1,
              ),
            ),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textOnSurfaceSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── 编辑表单（结果态） ────────────────────────

  Widget _buildEditForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 金额输入
        _buildFormLabel(context, l10n.amount),
        const SizedBox(height: 8),
        _buildAmountField(context),
        const SizedBox(height: 20),
        // 交易类型
        _buildFormLabel(context, l10n.type),
        const SizedBox(height: 8),
        _buildTypeToggle(context),
        const SizedBox(height: 20),
        // 分类选择（含 AI 推荐新分类）
        _buildFormLabel(context, l10n.category),
        const SizedBox(height: 8),
        _buildCategoryDropdown(context),
        const SizedBox(height: 20),
        // 日期选择
        _buildFormLabel(context, l10n.date),
        const SizedBox(height: 8),
        _buildDateField(context),
        const SizedBox(height: 20),
        // 备注输入
        _buildFormLabel(context, l10n.note),
        const SizedBox(height: 8),
        _buildNoteField(context),
      ],
    );
  }

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

  /// 构建类型切换的一个段（支出/收入）
  Widget _buildTypeSegment({
    required String typeValue,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedType == typeValue;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.glassFillAccent(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppTheme.textOnSurface(context)
                  : AppTheme.textOnSurfaceTertiary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.glassFillStrong(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.glassStroke(context)),
      ),
      child: Row(
        children: [
          _buildTypeSegment(
            typeValue: 'expense',
            label: l10n.expenseLabel,
            onTap: () => setState(() => _selectedType = 'expense'),
          ),
          _buildTypeSegment(
            typeValue: 'income',
            label: l10n.incomeLabel,
            onTap: () => setState(() => _selectedType = 'income'),
          ),
        ],
      ),
    );
  }

  /// 构建毛玻璃输入框通用的 InputDecoration
  InputDecoration _buildGlassInputDecoration({
    String? prefixText,
    TextStyle? prefixStyle,
    String? hintText,
    TextStyle? hintStyle,
  }) {
    return InputDecoration(
      prefixText: prefixText,
      prefixStyle: prefixStyle,
      hintText: hintText,
      hintStyle: hintStyle,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.glassStroke(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.glassStroke(context)),
      ),
      // 显式指定聚焦边框颜色，避免浅色主题下 primary=白色导致边框不可见
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2.0),
      ),
      filled: true,
      fillColor: AppTheme.glassFillStrong(context),
    );
  }

  Widget _buildAmountField(BuildContext context) {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textOnSurface(context),
      ),
      decoration: _buildGlassInputDecoration(
        prefixText: '¥ ',
        prefixStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textOnSurface(context),
        ),
      ),
    );
  }

  Widget _buildNoteField(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _noteController,
      minLines: 2,
      maxLines: 5,
      style: TextStyle(fontSize: 16, color: AppTheme.textOnSurface(context)),
      decoration: _buildGlassInputDecoration(
        hintText: l10n.addNoteHint,
        hintStyle: TextStyle(color: AppTheme.textOnSurfaceTertiary(context)),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Theme(
              data: isDark
                  ? ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: Colors.white.withValues(alpha: 0.6),
                        onPrimary: Colors.black,
                        surface: const Color(0xFF2A2A2A),
                      ),
                    )
                  : ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppTheme.accentBlue,
                        onPrimary: Colors.white,
                        surface: Colors.white,
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

  Widget _buildCategoryDropdown(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        // 筛选支出类型分类（语音输入默认创建支出账单）
        final expenseCategories = categories
            .where((c) => c.type == TransactionType.expense.value)
            .toList();

        // 如果当前选中的是 AI 推荐新分类（数据库中不存在），
        // 则保留选中值不变，稍后在 items 中添加该选项
        final categoryExists =
            _selectedCategoryName.isNotEmpty &&
            expenseCategories.any((c) => c.name == _selectedCategoryName);
        if (!categoryExists &&
            !_isNewCategory &&
            _selectedCategoryName.isNotEmpty) {
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
                l10n.selectCategory,
                style: TextStyle(
                  color: AppTheme.textOnSurfaceTertiary(context),
                ),
              ),
              dropdownColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
              items: [
                // 如果存在 AI 推荐的新分类，作为首个选项展示
                if (_isNewCategory && _selectedCategoryName.isNotEmpty)
                  DropdownMenuItem<String>(
                    value: _selectedCategoryName,
                    enabled: true,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF69DB7C),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCategoryName,
                          style: TextStyle(
                            color: AppTheme.textOnSurface(context),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x3369DB7C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.newCategoryRecommended,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF69DB7C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // 已有分类列表
                ...expenseCategories.map((c) {
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
                }),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategoryName = value;
                    // 判断用户选的是否为已有分类
                    _isNewCategory = !expenseCategories.any(
                      (c) => c.name == value,
                    );
                  });
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

// ─── 频率波纹 CustomPainter ─────────────────────

/// 频率响应波纹条绘制器，用于显示录音时的声音波纹动画
///
/// 绘制 7 条垂直条，录音中时条高随 [animationValue] 波动产生波纹效果，
/// 空闲/静止时显示为低矮的均匀条。
class _WaveformBarPainter extends CustomPainter {
  final double animationValue;
  final Color barColor;

  _WaveformBarPainter({required this.animationValue, required this.barColor});

  // 条数
  static const int barCount = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    // 计算每条宽度和间距，居中绘制
    final totalBarsWidth = barCount * 10.0 + (barCount - 1) * 5.0;
    final startX = (size.width - totalBarsWidth) / 2;

    // 最大/最小条高
    const maxBarHeight = 120.0;
    const minBarHeight = 30.0;

    for (int i = 0; i < barCount; i++) {
      // 用正弦波驱动各条不同高度，产生流动波纹效果
      // 每条有相位偏移，使波纹看起来从左向右传播
      final phase = (i / barCount) * math.pi * 2;
      // animationValue 范围 0~1，映射为 0~2π，作正弦驱动
      final wave = (math.sin(phase + animationValue * math.pi * 2) + 1) / 2;
      final barHeight = minBarHeight + (maxBarHeight - minBarHeight) * wave;

      // 计算条的位置（底部对齐居中）
      final x = startX + i * 15.0;
      final y = size.height - barHeight;

      // 圆角矩形
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 10, barHeight),
        const Radius.circular(5),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformBarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
