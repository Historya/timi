import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Timi'**
  String get appName;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @myBills.
  ///
  /// In en, this message translates to:
  /// **'My Bills'**
  String get myBills;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notification;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets (¥)'**
  String get totalAssets;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceInput;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @billDetail.
  ///
  /// In en, this message translates to:
  /// **'Bill Detail'**
  String get billDetail;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @editIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get editIncome;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Please create one first.'**
  String get noCategories;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @addNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addNoteHint;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get enterAmount;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @budgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'Budget remaining this month ¥{amount}'**
  String budgetRemaining(Object amount);

  /// No description provided for @budgetOverspent.
  ///
  /// In en, this message translates to:
  /// **'Budget overspent this month ¥{amount}'**
  String budgetOverspent(Object amount);

  /// No description provided for @monthBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget remaining this month'**
  String get monthBudgetLabel;

  /// No description provided for @monthOverspentLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget overspent this month'**
  String get monthOverspentLabel;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String errorLoading(Object error);

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get deleteConfirmMessage;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirm;

  /// No description provided for @cannotDelete.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete'**
  String get cannotDelete;

  /// No description provided for @cannotDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'This category has {count} transactions and cannot be deleted.\nPlease delete related transactions first.'**
  String cannotDeleteHint(Object count);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the category「{name}」?\nThis action cannot be undone.'**
  String confirmDeleteCategory(Object name);

  /// No description provided for @notInCurrentMonth.
  ///
  /// In en, this message translates to:
  /// **'This bill is not in the current accounting period'**
  String get notInCurrentMonth;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get backToToday;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Moth'**
  String get month;

  /// No description provided for @totalExpenseFor.
  ///
  /// In en, this message translates to:
  /// **'{year}年{month}月总支出'**
  String totalExpenseFor(Object month, Object year);

  /// No description provided for @annualTrend.
  ///
  /// In en, this message translates to:
  /// **'Annual Spending Trend'**
  String get annualTrend;

  /// No description provided for @weeklyTrend.
  ///
  /// In en, this message translates to:
  /// **'Weekly Spending Trend'**
  String get weeklyTrend;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month {arrow} {change}%'**
  String vsLastMonth(Object arrow, Object change);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense Categories'**
  String get expenseCategories;

  /// No description provided for @weekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {number}'**
  String weekLabel(Object number);

  /// No description provided for @zeroAmount.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get zeroAmount;

  /// No description provided for @monthOverChange.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get monthOverChange;

  /// No description provided for @monthLabel.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String monthLabel(Object month);

  /// No description provided for @loadCategoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get loadCategoryFailed;

  /// No description provided for @loadRankingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ranking'**
  String get loadRankingFailed;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @voiceAccounting.
  ///
  /// In en, this message translates to:
  /// **'Voice Accounting'**
  String get voiceAccounting;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysis;

  /// No description provided for @defaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// No description provided for @currencyCNY.
  ///
  /// In en, this message translates to:
  /// **'CNY ¥'**
  String get currencyCNY;

  /// No description provided for @budgetAlert.
  ///
  /// In en, this message translates to:
  /// **'Budget Alert'**
  String get budgetAlert;

  /// No description provided for @asrEngine.
  ///
  /// In en, this message translates to:
  /// **'Speech Engine'**
  String get asrEngine;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @engineDashScope.
  ///
  /// In en, this message translates to:
  /// **'Alibaba Cloud'**
  String get engineDashScope;

  /// No description provided for @engineTencent.
  ///
  /// In en, this message translates to:
  /// **'Tencent Cloud ASR'**
  String get engineTencent;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @testPassed.
  ///
  /// In en, this message translates to:
  /// **'Test Passed'**
  String get testPassed;

  /// No description provided for @testFailed.
  ///
  /// In en, this message translates to:
  /// **'Test Failed, Retry'**
  String get testFailed;

  /// No description provided for @runTest.
  ///
  /// In en, this message translates to:
  /// **'Run Test'**
  String get runTest;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// No description provided for @analysisEngine.
  ///
  /// In en, this message translates to:
  /// **'Analysis Engine'**
  String get analysisEngine;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @selectAsrEngine.
  ///
  /// In en, this message translates to:
  /// **'Select Speech Recognition Engine'**
  String get selectAsrEngine;

  /// No description provided for @engineDashScopeDesc.
  ///
  /// In en, this message translates to:
  /// **'Recommended, supports Chinese & English real-time recognition'**
  String get engineDashScopeDesc;

  /// No description provided for @engineTencentDesc.
  ///
  /// In en, this message translates to:
  /// **'Requires AppId / SecretId / SecretKey'**
  String get engineTencentDesc;

  /// No description provided for @editAppId.
  ///
  /// In en, this message translates to:
  /// **'Edit APP ID'**
  String get editAppId;

  /// No description provided for @editSecretId.
  ///
  /// In en, this message translates to:
  /// **'Edit SecretId'**
  String get editSecretId;

  /// No description provided for @editSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Edit SecretKey'**
  String get editSecretKey;

  /// No description provided for @editApiKey.
  ///
  /// In en, this message translates to:
  /// **'Edit API Key'**
  String get editApiKey;

  /// No description provided for @enterAppId.
  ///
  /// In en, this message translates to:
  /// **'Please enter Tencent Cloud APP ID'**
  String get enterAppId;

  /// No description provided for @enterSecretId.
  ///
  /// In en, this message translates to:
  /// **'Please enter Tencent Cloud SecretId'**
  String get enterSecretId;

  /// No description provided for @enterSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter Tencent Cloud SecretKey'**
  String get enterSecretKey;

  /// No description provided for @enterDashScopeKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter DashScope API Key'**
  String get enterDashScopeKey;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @unconfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get unconfigured;

  /// No description provided for @asrKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Please configure the API Key first'**
  String get asrKeyMissing;

  /// No description provided for @tencentCredMissing.
  ///
  /// In en, this message translates to:
  /// **'Please fill in complete Tencent Cloud ASR credentials'**
  String get tencentCredMissing;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful! ASR service available'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionFailed(Object error);

  /// No description provided for @aiAnalysisHint.
  ///
  /// In en, this message translates to:
  /// **'Used for AI semantic analysis (Tongyi Qianwen LLM). Leave empty to fallback to rule-based parsing.'**
  String get aiAnalysisHint;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @categoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get categoryManagement;

  /// No description provided for @expenseCategories_.
  ///
  /// In en, this message translates to:
  /// **'Expense Categories'**
  String get expenseCategories_;

  /// No description provided for @incomeCategories_.
  ///
  /// In en, this message translates to:
  /// **'Income Categories'**
  String get incomeCategories_;

  /// No description provided for @hintDragEdit.
  ///
  /// In en, this message translates to:
  /// **'Long press to reorder · Tap to edit'**
  String get hintDragEdit;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get selectIcon;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @enterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category name'**
  String get enterCategoryName;

  /// No description provided for @budgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Budget Settings'**
  String get budgetSettings;

  /// No description provided for @categoryBudget.
  ///
  /// In en, this message translates to:
  /// **'Category Budget'**
  String get categoryBudget;

  /// No description provided for @noBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'No monthly budget set yet'**
  String get noBudgetSet;

  /// No description provided for @enterMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Enter monthly budget'**
  String get enterMonthlyBudget;

  /// No description provided for @setBudget.
  ///
  /// In en, this message translates to:
  /// **'Set Budget'**
  String get setBudget;

  /// No description provided for @monthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudget;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @saveBudget.
  ///
  /// In en, this message translates to:
  /// **'Save Budget'**
  String get saveBudget;

  /// No description provided for @noCategoryBudget.
  ///
  /// In en, this message translates to:
  /// **'No category budgets yet\nTap \"Edit\" to set budgets for categories'**
  String get noCategoryBudget;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions, categories...'**
  String get searchHint;

  /// No description provided for @searchIdle.
  ///
  /// In en, this message translates to:
  /// **'Enter keywords to search'**
  String get searchIdle;

  /// No description provided for @searchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchLoading;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search error'**
  String get searchError;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions found'**
  String get noResults;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @monthlyExpense.
  ///
  /// In en, this message translates to:
  /// **'Monthly Expense'**
  String get monthlyExpense;

  /// No description provided for @monthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Income'**
  String get monthlyIncome;

  /// No description provided for @totalTransactions.
  ///
  /// In en, this message translates to:
  /// **'Total Transactions'**
  String get totalTransactions;

  /// No description provided for @featureSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get featureSettings;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @dataExport_.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport_;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @exportContent.
  ///
  /// In en, this message translates to:
  /// **'Export Content'**
  String get exportContent;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// No description provided for @exportAndShare.
  ///
  /// In en, this message translates to:
  /// **'Export & Share'**
  String get exportAndShare;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exporting;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// No description provided for @expenseOnly.
  ///
  /// In en, this message translates to:
  /// **'Expense Only'**
  String get expenseOnly;

  /// No description provided for @incomeOnly.
  ///
  /// In en, this message translates to:
  /// **'Income Only'**
  String get incomeOnly;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get exportSuccess;

  /// No description provided for @about_.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Minimal Voice Accounting'**
  String get appTagline;

  /// No description provided for @changelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelog;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'(c) 2024 Timi Team'**
  String get copyright;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} (Coming soon)'**
  String featureComingSoon(Object feature);

  /// No description provided for @viewChangelogHint.
  ///
  /// In en, this message translates to:
  /// **'View version history'**
  String get viewChangelogHint;

  /// No description provided for @viewTermsHint.
  ///
  /// In en, this message translates to:
  /// **'View terms of service'**
  String get viewTermsHint;

  /// No description provided for @viewPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'View privacy policy'**
  String get viewPrivacyHint;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @releaseToStop.
  ///
  /// In en, this message translates to:
  /// **'Release to stop'**
  String get releaseToStop;

  /// No description provided for @holdToTalk.
  ///
  /// In en, this message translates to:
  /// **'Hold to talk'**
  String get holdToTalk;

  /// No description provided for @confirmTransaction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transaction'**
  String get confirmTransaction;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @recognitionResult.
  ///
  /// In en, this message translates to:
  /// **'Recognition Result'**
  String get recognitionResult;

  /// No description provided for @waitingForSpeech.
  ///
  /// In en, this message translates to:
  /// **'Waiting for voice input...'**
  String get waitingForSpeech;

  /// No description provided for @recordingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recording saved successfully'**
  String get recordingSuccess;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @speechRecognitionFailed.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition failed: {error}'**
  String speechRecognitionFailed(Object error);

  /// No description provided for @micPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get micPermissionRequired;

  /// No description provided for @asrConfigRequired.
  ///
  /// In en, this message translates to:
  /// **'Please configure the speech recognition API Key in settings first'**
  String get asrConfigRequired;

  /// No description provided for @recommendedNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommendedNewCategory;

  /// No description provided for @newCategoryRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended new category'**
  String get newCategoryRecommended;

  /// No description provided for @expenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseLabel;

  /// No description provided for @incomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeLabel;

  /// No description provided for @editModeExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editModeExpense;

  /// No description provided for @editModeIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get editModeIncome;

  /// No description provided for @addModeExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addModeExpense;

  /// No description provided for @addModeIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addModeIncome;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get nextMonth;

  /// No description provided for @thisMonthIncome.
  ///
  /// In en, this message translates to:
  /// **'This Month\'s Income'**
  String get thisMonthIncome;

  /// No description provided for @thisMonthExpense.
  ///
  /// In en, this message translates to:
  /// **'This Month\'s Expense'**
  String get thisMonthExpense;

  /// No description provided for @dateRangeFormat.
  ///
  /// In en, this message translates to:
  /// **'{startYear}/{startMonth} – {endYear}/{endMonth}'**
  String dateRangeFormat(
    Object endMonth,
    Object endYear,
    Object startMonth,
    Object startYear,
  );

  /// No description provided for @dateFormatDetail.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day} {hour}:{minute}'**
  String dateFormatDetail(Object day, Object hour, Object minute, Object month);

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get loadFailed;

  /// No description provided for @recordingError.
  ///
  /// In en, this message translates to:
  /// **'Recording error: {error}'**
  String recordingError(Object error);

  /// No description provided for @noSpeechDetected.
  ///
  /// In en, this message translates to:
  /// **'No speech detected, please try again'**
  String get noSpeechDetected;

  /// No description provided for @gettingRecognitionResult.
  ///
  /// In en, this message translates to:
  /// **'Getting recognition result...'**
  String get gettingRecognitionResult;

  /// No description provided for @recordingMicPermission.
  ///
  /// In en, this message translates to:
  /// **'Unable to start recording: {error}'**
  String recordingMicPermission(Object error);

  /// No description provided for @keepAliveChannelName.
  ///
  /// In en, this message translates to:
  /// **'Background Service'**
  String get keepAliveChannelName;

  /// No description provided for @keepAliveChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Keeps Timi ready for quick expense tracking'**
  String get keepAliveChannelDesc;

  /// No description provided for @keepAliveNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Timi is ready, log anytime'**
  String get keepAliveNotificationTitle;

  /// No description provided for @keepAliveNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Tap to open and track'**
  String get keepAliveNotificationText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
