// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Timi';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get tabHome => '首页';

  @override
  String get myBills => '我的账单';

  @override
  String get notification => '通知';

  @override
  String get totalAssets => '总资产 (元)';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get addExpense => '添加支出';

  @override
  String get addIncome => '添加收入';

  @override
  String get voiceInput => '语音';

  @override
  String get more => '更多';

  @override
  String get recentTransactions => '最近交易';

  @override
  String get viewAll => '查看全部';

  @override
  String get noTransactions => '暂无交易记录';

  @override
  String get uncategorized => '未分类';

  @override
  String get billDetail => '账单详情';

  @override
  String get editExpense => '编辑支出';

  @override
  String get editIncome => '编辑收入';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get done => '完成';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get amount => '金额';

  @override
  String get selectCategory => '选择分类';

  @override
  String get noCategories => '暂无分类，请先在分类管理中创建';

  @override
  String get manageCategories => '管理分类';

  @override
  String get addNoteHint => '添加备注...';

  @override
  String get enterAmount => '请输入金额';

  @override
  String get enterValidAmount => '请输入有效金额';

  @override
  String get pleaseSelectCategory => '请选择分类';

  @override
  String budgetRemaining(Object amount) {
    return '本月预算剩余 ¥$amount';
  }

  @override
  String budgetOverspent(Object amount) {
    return '本月预算已超支 ¥$amount';
  }

  @override
  String get monthBudgetLabel => '本月预算剩余';

  @override
  String get monthOverspentLabel => '本月预算已超支';

  @override
  String get loading => '加载中...';

  @override
  String errorLoading(Object error) {
    return '加载失败：$error';
  }

  @override
  String get category => '分类';

  @override
  String get date => '日期';

  @override
  String get type => '类型';

  @override
  String get note => '备注';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get deleteTransaction => '删除交易';

  @override
  String get deleteConfirmMessage => '确定要删除这笔交易吗？';

  @override
  String get deleteConfirm => '删除';

  @override
  String get cannotDelete => '无法删除';

  @override
  String cannotDeleteHint(Object count) {
    return '该分类下有 $count 笔交易，无法删除。\n请先删除相关交易后再试。';
  }

  @override
  String get ok => '知道了';

  @override
  String confirmDeleteCategory(Object name) {
    return '确定要删除分类「$name」吗？\n此操作不可撤销。';
  }

  @override
  String get notInCurrentMonth => '该账目不在记账期间内';

  @override
  String get statistics => '支出统计';

  @override
  String get backToToday => '回到今天';

  @override
  String get week => '周';

  @override
  String get month => '月';

  @override
  String totalExpenseFor(Object month, Object year) {
    return '$year年$month月总支出';
  }

  @override
  String get annualTrend => '年度消费趋势';

  @override
  String get weeklyTrend => '本月各周消费趋势';

  @override
  String vsLastMonth(Object arrow, Object change) {
    return '较上月 $arrow $change%';
  }

  @override
  String get noData => '暂无数据';

  @override
  String get expenseCategories => '支出分类';

  @override
  String weekLabel(Object number) {
    return '第$number周';
  }

  @override
  String get zeroAmount => '0.00';

  @override
  String get monthOverChange => '较上月';

  @override
  String monthLabel(Object month) {
    return '$month月';
  }

  @override
  String get loadCategoryFailed => '分类加载失败';

  @override
  String get loadRankingFailed => '排行榜加载失败';

  @override
  String get settings => '设置';

  @override
  String get dataManagement => '数据管理';

  @override
  String get display => '显示';

  @override
  String get voiceAccounting => '语音记账';

  @override
  String get aiAnalysis => 'AI 语义分析';

  @override
  String get defaultCurrency => '默认货币';

  @override
  String get currencyCNY => '人民币 ¥';

  @override
  String get budgetAlert => '预算提醒';

  @override
  String get asrEngine => '语音识别引擎';

  @override
  String get defaultLabel => '默认';

  @override
  String get engineDashScope => '阿里云 DashScope';

  @override
  String get engineTencent => '腾讯云 ASR';

  @override
  String get testConnection => '测试连接';

  @override
  String get testPassed => '测试通过';

  @override
  String get testFailed => '测试失败，重试';

  @override
  String get runTest => '运行测试';

  @override
  String get testing => '测试中...';

  @override
  String get analysisEngine => '分析引擎';

  @override
  String get apiKey => 'API Key';

  @override
  String get selectAsrEngine => '选择语音识别引擎';

  @override
  String get engineDashScopeDesc => '推荐，支持中英文实时识别';

  @override
  String get engineTencentDesc => '需配置 AppId / SecretId / SecretKey';

  @override
  String get editAppId => '编辑 APP ID';

  @override
  String get editSecretId => '编辑 SecretId';

  @override
  String get editSecretKey => '编辑 SecretKey';

  @override
  String get editApiKey => '编辑 API Key';

  @override
  String get enterAppId => '请输入腾讯云 APP ID';

  @override
  String get enterSecretId => '请输入腾讯云 SecretId';

  @override
  String get enterSecretKey => '请输入腾讯云 SecretKey';

  @override
  String get enterDashScopeKey => '请输入 DashScope API Key';

  @override
  String get darkMode => '深色模式';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get unconfigured => '未配置';

  @override
  String get asrKeyMissing => '请先配置 API Key';

  @override
  String get tencentCredMissing => '请先填写完整的腾讯云 ASR 凭证';

  @override
  String get connectionSuccess => '连接成功！ASR 服务可用';

  @override
  String connectionFailed(Object error) {
    return '连接失败：$error';
  }

  @override
  String get aiAnalysisHint => '用于 AI 语义分析（通义千问 LLM），留空则降级到规则引擎解析。';

  @override
  String get unknown => '未知';

  @override
  String get categoryManagement => '分类管理';

  @override
  String get expenseCategories_ => '支出分类';

  @override
  String get incomeCategories_ => '收入分类';

  @override
  String get hintDragEdit => '长按拖动排序 · 点击编辑';

  @override
  String get newCategory => '添加分类';

  @override
  String get editCategory => '编辑分类';

  @override
  String get deleteCategory => '删除分类';

  @override
  String get noCategoriesYet => '暂无分类';

  @override
  String get categoryName => '分类名称';

  @override
  String get selectIcon => '选择图标';

  @override
  String get selectColor => '选择颜色';

  @override
  String get enterCategoryName => '请输入分类名称';

  @override
  String get budgetSettings => '预算设置';

  @override
  String get categoryBudget => '分类预算';

  @override
  String get noBudgetSet => '尚未设置月度预算';

  @override
  String get enterMonthlyBudget => '输入月度预算';

  @override
  String get setBudget => '设置预算';

  @override
  String get monthlyBudget => '月度预算';

  @override
  String get used => '已用';

  @override
  String get remaining => '剩余';

  @override
  String get saveBudget => '保存预算';

  @override
  String get noCategoryBudget => '暂无分类预算\n点击「编辑」为分类设置预算';

  @override
  String get search => '搜索';

  @override
  String get all => '全部';

  @override
  String get searchHint => '搜索交易、分类...';

  @override
  String get searchIdle => '输入关键词搜索交易';

  @override
  String get searchLoading => '搜索中...';

  @override
  String get searchError => '搜索出错';

  @override
  String get noResults => '未找到匹配的交易';

  @override
  String get searchResults => '搜索结果';

  @override
  String get profile => '我的';

  @override
  String get monthlyExpense => '本月支出';

  @override
  String get monthlyIncome => '本月收入';

  @override
  String get totalTransactions => '总交易';

  @override
  String get featureSettings => '⚙ 功能设置';

  @override
  String get categories => '分类管理';

  @override
  String get budget => '预算设置';

  @override
  String get dataExport => '数据导出';

  @override
  String get about => '关于';

  @override
  String get dataExport_ => '数据导出';

  @override
  String get dateRange => '时间范围';

  @override
  String get exportContent => '导出内容';

  @override
  String get exportFormat => '导出格式';

  @override
  String get exportAndShare => '导出并分享';

  @override
  String get exporting => '导出中…';

  @override
  String get allTransactions => '所有交易';

  @override
  String get expenseOnly => '仅支出';

  @override
  String get incomeOnly => '仅收入';

  @override
  String get exportSuccess => '导出成功';

  @override
  String get about_ => '关于';

  @override
  String get appTagline => '极简语音记账';

  @override
  String get changelog => '更新日志';

  @override
  String get termsOfService => '用户协议';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get copyright => '(c) 2024 Timi Team';

  @override
  String featureComingSoon(Object feature) {
    return '$feature（待实现）';
  }

  @override
  String get viewChangelogHint => '查看版本历史';

  @override
  String get viewTermsHint => '查看用户服务协议';

  @override
  String get viewPrivacyHint => '查看隐私保护政策';

  @override
  String get close => '关闭';

  @override
  String get releaseToStop => '松开结束';

  @override
  String get holdToTalk => '按住说话';

  @override
  String get confirmTransaction => '确定添加账目';

  @override
  String get analyzing => '正在分析...';

  @override
  String get listening => '正在聆听...';

  @override
  String get ready => '准备就绪';

  @override
  String get recognitionResult => '识别结果';

  @override
  String get waitingForSpeech => '等待语音输入...';

  @override
  String get recordingSuccess => '记账成功';

  @override
  String saveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String speechRecognitionFailed(Object error) {
    return '语音识别失败：$error';
  }

  @override
  String get micPermissionRequired => '需要麦克风权限才能录音';

  @override
  String get asrConfigRequired => '请先在设置中配置语音识别 API Key';

  @override
  String get recommendedNewCategory => '推荐新分类';

  @override
  String get newCategoryRecommended => '推荐新分类';

  @override
  String get expenseLabel => '支出';

  @override
  String get incomeLabel => '收入';

  @override
  String get editModeExpense => '编辑支出';

  @override
  String get editModeIncome => '编辑收入';

  @override
  String get addModeExpense => '添加支出';

  @override
  String get addModeIncome => '添加收入';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get thisMonthIncome => '本月收入';

  @override
  String get thisMonthExpense => '本月支出';

  @override
  String dateRangeFormat(
    Object endMonth,
    Object endYear,
    Object startMonth,
    Object startYear,
  ) {
    return '$startYear年$startMonth月 - $endYear年$endMonth月';
  }

  @override
  String dateFormatDetail(
    Object day,
    Object hour,
    Object minute,
    Object month,
  ) {
    return '$month月$day日 $hour:$minute';
  }

  @override
  String get loadFailed => '加载失败';

  @override
  String recordingError(Object error) {
    return '录音出错：$error';
  }

  @override
  String get noSpeechDetected => '未识别到语音内容，请重试';

  @override
  String get gettingRecognitionResult => '正在获取识别结果...';

  @override
  String recordingMicPermission(Object error) {
    return '无法启动录音：$error';
  }
}
