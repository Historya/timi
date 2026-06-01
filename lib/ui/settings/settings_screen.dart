import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timi/core/theme/app_theme.dart';
import 'package:timi/providers/database_provider.dart';
import 'package:timi/providers/ui_providers.dart';
import 'package:timi/services/asr_service.dart';
import 'package:timi/services/dashscope_asr_service.dart';
import 'package:timi/services/tencent_asr_service.dart';
import 'package:timi/l10n/app_localizations.dart';
import 'package:timi/ui/shared/widgets/top_notification.dart';

/// 设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const _SettingsHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(l10n.dataManagement),
                      const SizedBox(height: 10),
                      const _DataCard(),
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.display),
                      const SizedBox(height: 10),
                      const _DisplayCard(),
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.voiceAccounting),
                      const SizedBox(height: 10),
                      const _AsrSettingsCard(),
                      const SizedBox(height: 24),
                      _SectionTitle(l10n.aiAnalysis),
                      const SizedBox(height: 10),
                      const _AiAnalysisCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设置页面头部：返回按钮 + 标题
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          // 返回按钮 24px
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              PhosphorIconsLight.arrowLeft,
              color: AppTheme.textOnSurface(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // 标题 "设置" 20px bold 居中
          Expanded(
            child: Text(
              l10n.settings,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textOnSurface(context),
              ),
            ),
          ),
          // 右侧 24px 占位 spacer
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

/// 分节标题：13px 60% 透明度 粗体
class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppTheme.textOnSurface(context).withValues(alpha: 0.6),
      ),
    );
  }
}

/// 设置项行：高 52、子元素间距 12、水平 padding [4,0]
class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textOnSurface(context), size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textOnSurface(context),
              ),
            ),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// 分隔线：1px，使用主题感知毛玻璃填充色
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 50),
      color: AppTheme.glassFillStrong(context),
    );
  }
}

/// 尾部文字 14px 50% + caretRight 18px
class _TrailingText extends StatelessWidget {
  final String text;

  const _TrailingText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 文本支持溢出省略，防止因空间不足导致溢出
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textOnSurfaceTertiary(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          PhosphorIconsLight.caretRight,
          color: AppTheme.textOnSurface(context).withValues(alpha: 0.38),
          size: 18,
        ),
      ],
    );
  }
}

/// 自定义开关：44×24 radius 12，开启时绿色 #4ADE80
class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final VoidCallback? onChanged;

  const _ToggleSwitch({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: Container(
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? AppTheme.accentGreen : AppTheme.glassBlack26,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// 数据管理卡片 — 加载货币 / 分类 / 预算提醒，预算提醒可写回数据库
class _DataCard extends ConsumerStatefulWidget {
  const _DataCard();

  @override
  ConsumerState<_DataCard> createState() => _DataCardState();
}

class _DataCardState extends ConsumerState<_DataCard> {
  // 缓存预算提醒开关状态，避免每次构建都查询数据库
  bool? _budgetAlert;

  @override
  void initState() {
    super.initState();
    // 在首次构建后异步加载预算提醒状态
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBudgetAlert());
  }

  /// 从 SettingsTable 加载预算提醒开关状态
  Future<void> _loadBudgetAlert() async {
    final dao = ref.read(settingsDaoProvider);
    final value = await dao.get('budget_alert');
    if (mounted) {
      setState(() => _budgetAlert = value == 'true');
    }
  }

  /// 切换预算提醒并写回数据库
  Future<void> _toggleBudgetAlert() async {
    final dao = ref.read(settingsDaoProvider);
    final newValue = _budgetAlert != true;
    await dao.set('budget_alert', newValue.toString());
    if (mounted) {
      setState(() => _budgetAlert = newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(settingsDaoProvider);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: AppTheme.glassDecoration(
        fill: AppTheme.glassFillStrong(context),
        stroke: AppTheme.glassStroke(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingRow(
            icon: PhosphorIconsLight.currencyCircleDollar,
            label: l10n.defaultCurrency,
            trailing: FutureBuilder<String?>(
              future: dao.get('currency'),
              builder: (context, snapshot) =>
                  _TrailingText(snapshot.data ?? l10n.currencyCNY),
            ),
          ),
          const _Divider(),
          _SettingRow(
            icon: PhosphorIconsLight.bell,
            label: l10n.budgetAlert,
            trailing: _ToggleSwitch(
              value: _budgetAlert ?? false,
              onChanged: _toggleBudgetAlert,
            ),
          ),
        ],
      ),
    );
  }
}

/// 语音记账 ASR 设置卡片
///
/// 支持选择引擎类型（阿里云 DashScope / 腾讯云 ASR）并编辑对应凭证。
class _AsrSettingsCard extends ConsumerStatefulWidget {
  const _AsrSettingsCard();

  @override
  ConsumerState<_AsrSettingsCard> createState() => _AsrSettingsCardState();
}

class _AsrSettingsCardState extends ConsumerState<_AsrSettingsCard> {
  String _engine = 'dashscope'; // 当前引擎类型
  String _dashscopeKey = '';
  String _tencentAppId = '';
  String _tencentSecretId = '';
  String _tencentSecretKey = '';
  bool _loading = true;
  bool _testing = false; // 是否正在测试连接
  String _testStatus = 'untested'; // 测试状态：untested / success / failure

  @override
  void initState() {
    super.initState();
    // 在首次构建后异步加载设置
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  /// 从 SettingsTable 加载所有 ASR 配置
  Future<void> _loadSettings() async {
    final dao = ref.read(settingsDaoProvider);
    final engine = await dao.get('asr_engine') ?? 'dashscope';
    final dashscopeKey = await dao.get('dashscope_api_key') ?? '';
    final tencentAppId = await dao.get('tencent_app_id') ?? '';
    final tencentSecretId = await dao.get('tencent_secret_id') ?? '';
    final tencentSecretKey = await dao.get('tencent_secret_key') ?? '';
    if (mounted) {
      setState(() {
        _engine = engine;
        _dashscopeKey = dashscopeKey;
        _tencentAppId = tencentAppId;
        _tencentSecretId = tencentSecretId;
        _tencentSecretKey = tencentSecretKey;
        _loading = false;
        _testStatus = 'untested';
      });
    }
  }

  /// 对凭证值脱敏显示：保留前 3 位和末 4 位，中间替换为 ****
  String _maskKey(String value) {
    if (value.length < 8) return '****';
    return '${value.substring(0, 3)}****${value.substring(value.length - 4)}';
  }

  /// 弹出引擎选择底部弹窗
  void _showEnginePicker() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // 弹窗标题
              Text(
                l10n.selectAsrEngine,
                style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textOnSurface(context),
              ),
            ),
            const SizedBox(height: 16),
            // 阿里云 DashScope 选项
            ListTile(
              leading: Icon(
                PhosphorIconsLight.cloud,
                color: AppTheme.textOnSurface(context),
              ),
              title: Text(
                l10n.engineDashScope,
                style: TextStyle(color: AppTheme.textOnSurface(context)),
              ),
              subtitle: Text(
                l10n.engineDashScopeDesc,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textOnSurfaceTertiary(context),
                ),
              ),
              trailing: _engine == 'dashscope'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 默认引擎标识
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.defaultLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          PhosphorIconsFill.checkCircle,
                          color: AppTheme.accentGreen,
                          size: 22,
                        ),
                      ],
                    )
                  : null,
              onTap: () {
                Navigator.of(ctx).pop();
                _setEngine('dashscope');
              },
            ),
            // 腾讯云 ASR 选项
            ListTile(
              leading: Icon(
                PhosphorIconsLight.cloud,
                color: AppTheme.textOnSurface(context),
              ),
              title: Text(
                l10n.engineTencent,
                style: TextStyle(color: AppTheme.textOnSurface(context)),
              ),
              subtitle: Text(
                l10n.engineTencentDesc,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textOnSurfaceTertiary(context),
                ),
              ),
              trailing: _engine == 'tencent'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 默认引擎标识
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.defaultLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          PhosphorIconsFill.checkCircle,
                          color: AppTheme.accentGreen,
                          size: 22,
                        ),
                      ],
                    )
                  : null,
              onTap: () {
                Navigator.of(ctx).pop();
                _setEngine('tencent');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 切换引擎类型并写入数据库
  Future<void> _setEngine(String engine) async {
    final dao = ref.read(settingsDaoProvider);
    await dao.set('asr_engine', engine);
    if (mounted) {
      setState(() {
        _engine = engine;
        _testStatus = 'untested';
      });
    }
  }

  /// 弹出编辑单字段凭证对话框（通用）
  Future<void> _editCredential({
    required String title,
    required String hintText,
    required String dbKey,
    required String currentValue,
  }) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentValue);
    if (!context.mounted) return;
    final newValue = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            // 显式指定聚焦边框颜色，避免浅色主题下 primary=白色导致边框不可见
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.accentBlue, width: 2.0),
            ),
          ),
          style: TextStyle(color: AppTheme.textOnSurface(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: AppTheme.textOnSurface(context)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: Text(
            l10n.confirm,
            style: TextStyle(color: AppTheme.textOnSurface(context)),
          ),
          ),
        ],
      ),
    );
    if (newValue != null && newValue.isNotEmpty && context.mounted) {
      final dao = ref.read(settingsDaoProvider);
      await dao.set(dbKey, newValue);
      // 更新本地状态缓存，并重置测试状态
      setState(() {
        _testStatus = 'untested';
        if (dbKey == 'dashscope_api_key') {
          _dashscopeKey = newValue;
        } else if (dbKey == 'tencent_app_id') {
          _tencentAppId = newValue;
        } else if (dbKey == 'tencent_secret_id') {
          _tencentSecretId = newValue;
        } else if (dbKey == 'tencent_secret_key') {
          _tencentSecretKey = newValue;
        }
      });
    }
  }

  /// 测试 ASR 服务连通性
  ///
  /// 使用当前配置创建引擎实例，尝试连接后立即断开。
  /// DashScope 和 Tencent 分别使用不同的凭证字段。
  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context);
    // 验证凭证是否已填写
    if (_engine == 'dashscope' && _dashscopeKey.isEmpty) {
      TopNotification.show(
        context,
        message: l10n.asrKeyMissing,
        type: TopNotificationType.warning,
      );
      return;
    }
    if (_engine == 'tencent') {
      if (_tencentAppId.isEmpty ||
          _tencentSecretId.isEmpty ||
          _tencentSecretKey.isEmpty) {
        TopNotification.show(
          context,
          message: l10n.tencentCredMissing,
          type: TopNotificationType.warning,
        );
        return;
      }
    }

    setState(() => _testing = true);

    // 根据引擎类型创建服务实例
    final AsrService service;
    if (_engine == 'tencent') {
      service = TencentAsrService(
        appId: _tencentAppId,
        secretId: _tencentSecretId,
        secretKey: _tencentSecretKey,
      );
    } else {
      service = DashScopeAsrService();
    }

    try {
      // 连接测试（带 10 秒超时）
      if (_engine == 'dashscope') {
        await service
            .connect(apiKey: _dashscopeKey, model: '')
            .timeout(const Duration(seconds: 10));
      } else {
        await service
            .connect(apiKey: '', model: '')
            .timeout(const Duration(seconds: 10));
      }
      // 连接成功，断开后提示
      await service.disconnect();
      if (mounted) {
        TopNotification.show(
          context,
          message: l10n.connectionSuccess,
          type: TopNotificationType.success,
        );
        setState(() => _testStatus = 'success');
      }
    } catch (e) {
      // 连接失败，断开清理后报错
      await service.disconnect();
      if (mounted) {
        TopNotification.show(
          context,
          message: l10n.connectionFailed(e.toString()),
          type: TopNotificationType.error,
        );
        setState(() => _testStatus = 'failure');
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 加载中时显示毛玻璃骨架
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: AppTheme.glassDecoration(
          fill: AppTheme.glassFillStrong(context),
          stroke: AppTheme.glassStroke(context),
        ),
        child: const SizedBox(
          height: 52,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: AppTheme.glassDecoration(
        fill: AppTheme.glassFillStrong(context),
        stroke: AppTheme.glassStroke(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildConfigRows(),
      ),
    );
  }

  /// 根据引擎类型构建所有配置行列表（引擎选择行 + 凭证编辑行）
  List<Widget> _buildConfigRows() {
    final l10n = AppLocalizations.of(context);
    final rows = <Widget>[];
    // 引擎选择行（单独实现以显示引擎名称）
    rows.add(
      InkWell(
        onTap: _showEnginePicker,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsLight.microphone,
                  color: AppTheme.textOnSurface(context),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.asrEngine,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textOnSurface(context),
                  ),
                ),
                const Spacer(),
                // 默认引擎标识徽标
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.defaultLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 用 Flexible 包裹尾部，防止徽标+引擎名称+箭头溢出
                Flexible(
                  child: _TrailingText(
                    _engine == 'tencent' ? l10n.engineTencent : l10n.engineDashScope,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (_engine == 'tencent') {
      // 腾讯云 ASR 凭证：APP ID、SecretId、SecretKey
      rows.add(const _Divider());
      rows.add(
        InkWell(
          onTap: () => _editCredential(
            title: l10n.editAppId,
            hintText: l10n.enterAppId,
            dbKey: 'tencent_app_id',
            currentValue: _tencentAppId,
          ),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsLight.identificationBadge,
                    color: AppTheme.textOnSurface(context),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'APP ID',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
                  const Spacer(),
                  _TrailingText(_maskKey(_tencentAppId)),
                ],
              ),
            ),
          ),
        ),
      );
      rows.add(const _Divider());
      rows.add(
        InkWell(
          onTap: () => _editCredential(
            title: l10n.editSecretId,
            hintText: l10n.enterSecretId,
            dbKey: 'tencent_secret_id',
            currentValue: _tencentSecretId,
          ),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsLight.key,
                    color: AppTheme.textOnSurface(context),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SecretId',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
                  const Spacer(),
                  _TrailingText(_maskKey(_tencentSecretId)),
                ],
              ),
            ),
          ),
        ),
      );
      rows.add(const _Divider());
      rows.add(
        InkWell(
          onTap: () => _editCredential(
            title: l10n.editSecretKey,
            hintText: l10n.enterSecretKey,
            dbKey: 'tencent_secret_key',
            currentValue: _tencentSecretKey,
          ),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsLight.lock,
                    color: AppTheme.textOnSurface(context),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SecretKey',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
                  const Spacer(),
                  _TrailingText(_maskKey(_tencentSecretKey)),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // DashScope 凭证：API Key
      rows.add(const _Divider());
      rows.add(
        InkWell(
          onTap: () => _editCredential(
            title: l10n.editApiKey,
            hintText: l10n.enterDashScopeKey,
            dbKey: 'dashscope_api_key',
            currentValue: _dashscopeKey,
          ),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsLight.key,
                    color: AppTheme.textOnSurface(context),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'API Key',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textOnSurface(context),
                    ),
                  ),
                  const Spacer(),
                  _TrailingText(_maskKey(_dashscopeKey)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 测试连接按钮（始终显示在所有配置行末尾）
    rows.add(const _Divider());

    // 根据测试状态确定按钮配色
    Color statusColor;
    String btnText;
    IconData rowIcon;
    switch (_testStatus) {
      case 'success':
        statusColor = AppTheme.accentGreen;
        btnText = l10n.testPassed;
        rowIcon = PhosphorIconsLight.checkCircle;
        break;
      case 'failure':
        statusColor = Colors.redAccent;
        btnText = l10n.testFailed;
        rowIcon = PhosphorIconsLight.warningCircle;
        break;
      default:
        // 未测试：橙色警告色
        statusColor = Colors.orange;
        btnText = l10n.runTest;
        rowIcon = PhosphorIconsLight.wifiHigh;
    }

    rows.add(
      SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                _testing ? PhosphorIconsLight.circleNotch : rowIcon,
                color: _testing
                    ? AppTheme.textOnSurface(context).withValues(alpha: 0.5)
                    : statusColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                _testing ? l10n.testing : l10n.testConnection,
                style: TextStyle(
                  fontSize: 15,
                  color: _testing
                      ? AppTheme.textOnSurface(context).withValues(alpha: 0.5)
                      : statusColor,
                ),
              ),
              const Spacer(),
              if (_testing)
                // 测试中显示旋转加载指示器
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textOnSurface(
                      context,
                    ).withValues(alpha: 0.5),
                  ),
                )
              else
                // 可点击的测试按钮
                GestureDetector(
                  onTap: _testConnection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      btnText,
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return rows;
  }
}

/// AI 语义分析设置卡片
///
/// 配置用于 AI 语义解析的引擎和凭证。
/// 与语音识别（ASR）的 API Key 相互独立，可分别配置。
/// 当前支持：阿里云 DashScope（通义千问 LLM）
class _AiAnalysisCard extends ConsumerStatefulWidget {
  const _AiAnalysisCard();

  @override
  ConsumerState<_AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends ConsumerState<_AiAnalysisCard> {
  String _engine = 'dashscope'; // 当前引擎类型
  String _llmApiKey = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // 首次构建后异步加载设置
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  /// 从 SettingsTable 加载语义分析配置
  Future<void> _loadSettings() async {
    final dao = ref.read(settingsDaoProvider);
    final engine = await dao.get('semantic_parser_engine') ?? 'dashscope';
    final key = await dao.get('dashscope_llm_api_key') ?? '';
    if (mounted) {
      setState(() {
        _engine = engine;
        _llmApiKey = key;
        _loading = false;
      });
    }
  }

  /// 对凭证值脱敏显示：保留前 3 位和末 4 位，中间替换为 ****
  String _maskKey(String value) {
    if (value.length < 8) return '****';
    return '${value.substring(0, 3)}****${value.substring(value.length - 4)}';
  }

  /// 弹出编辑 API Key 对话框
  ///
  /// 提交空字符串可清空密钥。
  Future<void> _editApiKey() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _llmApiKey);
    if (!context.mounted) return;
    final newValue = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(l10n.editApiKey),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'sk-xxxxxxxxxxxxxx',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(color: AppTheme.textOnSurface(context)),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aiAnalysisHint,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textOnSurfaceTertiary(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (newValue != null && context.mounted) {
      final dao = ref.read(settingsDaoProvider);
      await dao.set('dashscope_llm_api_key', newValue);
      if (mounted) {
        setState(() => _llmApiKey = newValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 加载中显示毛玻璃骨架
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: AppTheme.glassDecoration(
          fill: AppTheme.glassFillStrong(context),
          stroke: AppTheme.glassStroke(context),
        ),
        child: const SizedBox(
          height: 52,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: AppTheme.glassDecoration(
        fill: AppTheme.glassFillStrong(context),
        stroke: AppTheme.glassStroke(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 引擎名称行（仅展示，当前仅 DashScope 一个引擎）
          _buildEngineRow(context),
          const _Divider(),
          // API Key 编辑行
          InkWell(
            onTap: _editApiKey,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsLight.key,
                      color: AppTheme.textOnSurface(context),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'API Key',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textOnSurface(context),
                      ),
                    ),
                    const Spacer(),
                    _TrailingText(
                      _llmApiKey.isEmpty ? l10n.unconfigured : _maskKey(_llmApiKey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 说明文字行（非交互）
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 0, 16, 8),
            child: Text(
              l10n.aiAnalysisHint,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textOnSurfaceTertiary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建引擎信息行：展示当前使用的 AI 分析引擎
  Widget _buildEngineRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              PhosphorIconsLight.magicWand,
              color: AppTheme.textOnSurface(context),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              l10n.analysisEngine,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textOnSurface(context),
              ),
            ),
            const Spacer(),
            _TrailingText(_engine == 'dashscope' ? l10n.engineDashScope : l10n.unknown),
          ],
        ),
      ),
    );
  }
}

class _DisplayCard extends ConsumerWidget {
  const _DisplayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // 监听当前主题模式
    final themeMode = ref.watch(themeModeProvider);
    // 获取 SettingsDao 实例
    final dao = ref.watch(settingsDaoProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: AppTheme.glassDecoration(
        fill: AppTheme.glassFillStrong(context),
        stroke: AppTheme.glassStroke(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingRow(
            icon: PhosphorIconsLight.moon,
            label: l10n.darkMode,
            trailing: _ToggleSwitch(
              // 判断当前是否实际处于深色模式（考虑跟随系统的情况）
              value: switch (themeMode) {
                ThemeMode.dark => true,
                ThemeMode.light => false,
                ThemeMode.system =>
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark,
              },
              onChanged: () {
                ref.read(themeModeProvider.notifier).toggle();
              },
            ),
          ),
          const _Divider(),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Theme.of(context).colorScheme.surface,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      // 弹窗标题
                      Text(
                        l10n.selectLanguage,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textOnSurface(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 中文选项
                      ListTile(
                        leading: Icon(
                          PhosphorIconsLight.checkCircle,
                          color: AppTheme.textOnSurface(context),
                        ),
                        title: Text(
                          l10n.chinese,
                          style: TextStyle(
                            color: AppTheme.textOnSurface(context),
                          ),
                        ),
                        onTap: () {
                          ref.read(localeProvider.notifier).setLanguage('zh');
                          Navigator.pop(ctx);
                        },
                      ),
                      // 英文选项
                      ListTile(
                        leading: Icon(
                          PhosphorIconsLight.translate,
                          color: AppTheme.textOnSurface(context),
                        ),
                        title: Text(
                          l10n.english,
                          style: TextStyle(
                            color: AppTheme.textOnSurface(context),
                          ),
                        ),
                        onTap: () {
                          ref.read(localeProvider.notifier).setLanguage('en');
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
            child: _SettingRow(
              icon: PhosphorIconsLight.translate,
              label: l10n.language,
              trailing: FutureBuilder<String?>(
                future: dao.get('language'),
                builder: (context, snapshot) => _TrailingText(
                  snapshot.data == 'en' ? l10n.english : l10n.chinese,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
