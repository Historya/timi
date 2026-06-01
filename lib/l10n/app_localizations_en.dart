// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Timi';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tabHome => 'Home';

  @override
  String get myBills => 'My Bills';

  @override
  String get notification => 'Notifications';

  @override
  String get totalAssets => 'Total Assets (¥)';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get addIncome => 'Add Income';

  @override
  String get voiceInput => 'Voice';

  @override
  String get more => 'More';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get billDetail => 'Bill Detail';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get editIncome => 'Edit Income';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get amount => 'Amount';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get noCategories => 'No categories yet. Please create one first.';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get addNoteHint => 'Add a note...';

  @override
  String get enterAmount => 'Please enter an amount';

  @override
  String get enterValidAmount => 'Please enter a valid amount';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String budgetRemaining(Object amount) {
    return 'Budget remaining this month ¥$amount';
  }

  @override
  String budgetOverspent(Object amount) {
    return 'Budget overspent this month ¥$amount';
  }

  @override
  String get monthBudgetLabel => 'Budget remaining this month';

  @override
  String get monthOverspentLabel => 'Budget overspent this month';

  @override
  String get loading => 'Loading...';

  @override
  String errorLoading(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String get category => 'Category';

  @override
  String get date => 'Date';

  @override
  String get type => 'Type';

  @override
  String get note => 'Note';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this transaction?';

  @override
  String get deleteConfirm => 'Delete';

  @override
  String get cannotDelete => 'Cannot Delete';

  @override
  String cannotDeleteHint(Object count) {
    return 'This category has $count transactions and cannot be deleted.\nPlease delete related transactions first.';
  }

  @override
  String get ok => 'OK';

  @override
  String confirmDeleteCategory(Object name) {
    return 'Are you sure you want to delete the category「$name」?\nThis action cannot be undone.';
  }

  @override
  String get notInCurrentMonth =>
      'This bill is not in the current accounting period';

  @override
  String get statistics => 'Expense Statistics';

  @override
  String get backToToday => 'Back to Today';

  @override
  String get week => 'Week';

  @override
  String get month => 'Moth';

  @override
  String totalExpenseFor(Object month, Object year) {
    return '$year年$month月总支出';
  }

  @override
  String get annualTrend => 'Annual Spending Trend';

  @override
  String get weeklyTrend => 'Weekly Spending Trend';

  @override
  String vsLastMonth(Object arrow, Object change) {
    return 'vs last month $arrow $change%';
  }

  @override
  String get noData => 'No data';

  @override
  String get expenseCategories => 'Expense Categories';

  @override
  String weekLabel(Object number) {
    return 'Week $number';
  }

  @override
  String get zeroAmount => '0.00';

  @override
  String get monthOverChange => 'vs last month';

  @override
  String monthLabel(Object month) {
    return 'M';
  }

  @override
  String get loadCategoryFailed => 'Failed to load categories';

  @override
  String get loadRankingFailed => 'Failed to load ranking';

  @override
  String get settings => 'Settings';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get display => 'Display';

  @override
  String get voiceAccounting => 'Voice Accounting';

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String get defaultCurrency => 'Default Currency';

  @override
  String get currencyCNY => 'CNY ¥';

  @override
  String get budgetAlert => 'Budget Alert';

  @override
  String get asrEngine => 'Speech Engine';

  @override
  String get defaultLabel => 'Default';

  @override
  String get engineDashScope => 'Alibaba Cloud';

  @override
  String get engineTencent => 'Tencent Cloud ASR';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get testPassed => 'Test Passed';

  @override
  String get testFailed => 'Test Failed, Retry';

  @override
  String get runTest => 'Run Test';

  @override
  String get testing => 'Testing...';

  @override
  String get analysisEngine => 'Analysis Engine';

  @override
  String get apiKey => 'API Key';

  @override
  String get selectAsrEngine => 'Select Speech Recognition Engine';

  @override
  String get engineDashScopeDesc =>
      'Recommended, supports Chinese & English real-time recognition';

  @override
  String get engineTencentDesc => 'Requires AppId / SecretId / SecretKey';

  @override
  String get editAppId => 'Edit APP ID';

  @override
  String get editSecretId => 'Edit SecretId';

  @override
  String get editSecretKey => 'Edit SecretKey';

  @override
  String get editApiKey => 'Edit API Key';

  @override
  String get enterAppId => 'Please enter Tencent Cloud APP ID';

  @override
  String get enterSecretId => 'Please enter Tencent Cloud SecretId';

  @override
  String get enterSecretKey => 'Please enter Tencent Cloud SecretKey';

  @override
  String get enterDashScopeKey => 'Please enter DashScope API Key';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get chinese => 'Chinese';

  @override
  String get english => 'English';

  @override
  String get unconfigured => 'Not configured';

  @override
  String get asrKeyMissing => 'Please configure the API Key first';

  @override
  String get tencentCredMissing =>
      'Please fill in complete Tencent Cloud ASR credentials';

  @override
  String get connectionSuccess =>
      'Connection successful! ASR service available';

  @override
  String connectionFailed(Object error) {
    return 'Connection failed: $error';
  }

  @override
  String get aiAnalysisHint =>
      'Used for AI semantic analysis (Tongyi Qianwen LLM). Leave empty to fallback to rule-based parsing.';

  @override
  String get unknown => 'Unknown';

  @override
  String get categoryManagement => 'Category Management';

  @override
  String get expenseCategories_ => 'Expense Categories';

  @override
  String get incomeCategories_ => 'Income Categories';

  @override
  String get hintDragEdit => 'Long press to reorder · Tap to edit';

  @override
  String get newCategory => 'New Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get categoryName => 'Category Name';

  @override
  String get selectIcon => 'Select Icon';

  @override
  String get selectColor => 'Select Color';

  @override
  String get enterCategoryName => 'Please enter a category name';

  @override
  String get budgetSettings => 'Budget Settings';

  @override
  String get categoryBudget => 'Category Budget';

  @override
  String get noBudgetSet => 'No monthly budget set yet';

  @override
  String get enterMonthlyBudget => 'Enter monthly budget';

  @override
  String get setBudget => 'Set Budget';

  @override
  String get monthlyBudget => 'Monthly Budget';

  @override
  String get used => 'Used';

  @override
  String get remaining => 'Remaining';

  @override
  String get saveBudget => 'Save Budget';

  @override
  String get noCategoryBudget =>
      'No category budgets yet\nTap \"Edit\" to set budgets for categories';

  @override
  String get search => 'Search';

  @override
  String get all => 'All';

  @override
  String get searchHint => 'Search transactions, categories...';

  @override
  String get searchIdle => 'Enter keywords to search';

  @override
  String get searchLoading => 'Searching...';

  @override
  String get searchError => 'Search error';

  @override
  String get noResults => 'No matching transactions found';

  @override
  String get searchResults => 'Search Results';

  @override
  String get profile => 'Profile';

  @override
  String get monthlyExpense => 'Monthly Expense';

  @override
  String get monthlyIncome => 'Monthly Income';

  @override
  String get totalTransactions => 'Total Transactions';

  @override
  String get featureSettings => 'Settings';

  @override
  String get categories => 'Categories';

  @override
  String get budget => 'Budget';

  @override
  String get dataExport => 'Data Export';

  @override
  String get about => 'About';

  @override
  String get dataExport_ => 'Data Export';

  @override
  String get dateRange => 'Date Range';

  @override
  String get exportContent => 'Export Content';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get exportAndShare => 'Export & Share';

  @override
  String get allTransactions => 'All Transactions';

  @override
  String get expenseOnly => 'Expense Only';

  @override
  String get incomeOnly => 'Income Only';

  @override
  String get exportSuccess => 'Export successful';

  @override
  String get about_ => 'About';

  @override
  String get appTagline => 'Minimal Voice Accounting';

  @override
  String get changelog => 'Changelog';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get copyright => '(c) 2024 Timi Team';

  @override
  String featureComingSoon(Object feature) {
    return '$feature (Coming soon)';
  }

  @override
  String get viewChangelogHint => 'View version history';

  @override
  String get viewTermsHint => 'View terms of service';

  @override
  String get viewPrivacyHint => 'View privacy policy';

  @override
  String get close => 'Close';

  @override
  String get releaseToStop => 'Release to stop';

  @override
  String get holdToTalk => 'Hold to talk';

  @override
  String get confirmTransaction => 'Confirm Transaction';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get listening => 'Listening...';

  @override
  String get ready => 'Ready';

  @override
  String get recognitionResult => 'Recognition Result';

  @override
  String get waitingForSpeech => 'Waiting for voice input...';

  @override
  String get recordingSuccess => 'Recording saved successfully';

  @override
  String saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String speechRecognitionFailed(Object error) {
    return 'Speech recognition failed: $error';
  }

  @override
  String get micPermissionRequired => 'Microphone permission required';

  @override
  String get asrConfigRequired =>
      'Please configure the speech recognition API Key in settings first';

  @override
  String get recommendedNewCategory => 'Recommended';

  @override
  String get newCategoryRecommended => 'Recommended new category';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get incomeLabel => 'Income';

  @override
  String get editModeExpense => 'Edit Expense';

  @override
  String get editModeIncome => 'Edit Income';

  @override
  String get addModeExpense => 'Add Expense';

  @override
  String get addModeIncome => 'Add Income';

  @override
  String get previousMonth => 'Previous Month';

  @override
  String get nextMonth => 'Next Month';

  @override
  String get thisMonthIncome => 'This Month\'s Income';

  @override
  String get thisMonthExpense => 'This Month\'s Expense';

  @override
  String dateRangeFormat(
    Object endMonth,
    Object endYear,
    Object startMonth,
    Object startYear,
  ) {
    return '$startYear/$startMonth – $endYear/$endMonth';
  }

  @override
  String dateFormatDetail(
    Object day,
    Object hour,
    Object minute,
    Object month,
  ) {
    return '$month/$day $hour:$minute';
  }

  @override
  String get loadFailed => 'Failed to load';

  @override
  String recordingError(Object error) {
    return 'Recording error: $error';
  }

  @override
  String get noSpeechDetected => 'No speech detected, please try again';

  @override
  String get gettingRecognitionResult => 'Getting recognition result...';

  @override
  String recordingMicPermission(Object error) {
    return 'Unable to start recording: $error';
  }
}
