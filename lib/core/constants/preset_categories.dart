// 预设分类数据
//
// 应用首次启动时插入数据库的默认支出/收入分类。
// 用户可自行编辑、删除或新增分类。

/// 单个预设分类的数据结构
class PresetCategory {
  final String name;
  final String icon;
  final String color;
  final String type;
  final int sortOrder;

  const PresetCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.sortOrder,
  });
}

/// 预设支出分类
const List<PresetCategory> presetExpenseCategories = [
  PresetCategory(name: '餐饮', icon: 'food', color: '#FF6B6B', type: 'expense', sortOrder: 0),
  PresetCategory(name: '交通出行', icon: 'car', color: '#4DABF7', type: 'expense', sortOrder: 1),
  PresetCategory(name: '购物消费', icon: 'shopping', color: '#FFA94D', type: 'expense', sortOrder: 2),
  PresetCategory(name: '住房', icon: 'house', color: '#69DB7C', type: 'expense', sortOrder: 3),
  PresetCategory(name: '娱乐', icon: 'game', color: '#9775FA', type: 'expense', sortOrder: 4),
  PresetCategory(name: '医疗', icon: 'firstAid', color: '#FF8787', type: 'expense', sortOrder: 5),
  PresetCategory(name: '通讯', icon: 'phone', color: '#74C0FC', type: 'expense', sortOrder: 6),
  PresetCategory(name: '教育', icon: 'book', color: '#748FFC', type: 'expense', sortOrder: 7),
  PresetCategory(name: '服饰', icon: 'bag', color: '#F783AC', type: 'expense', sortOrder: 8),
  PresetCategory(name: '人情社交', icon: 'gift', color: '#FFD43B', type: 'expense', sortOrder: 9),
  PresetCategory(name: '宠物', icon: 'pawPrint', color: '#DDA0DD', type: 'expense', sortOrder: 10),
  PresetCategory(name: '其他', icon: 'dotsThree', color: '#FFC078', type: 'expense', sortOrder: 11),
];

/// 预设收入分类
const List<PresetCategory> presetIncomeCategories = [
  PresetCategory(name: '工资', icon: 'money', color: '#38D9A9', type: 'income', sortOrder: 0),
  PresetCategory(name: '奖金', icon: 'gift', color: '#FFD43B', type: 'income', sortOrder: 1),
  PresetCategory(name: '理财收益', icon: 'bag', color: '#66D9E8', type: 'income', sortOrder: 2),
  PresetCategory(name: '兼职', icon: 'wrench', color: '#B197FC', type: 'income', sortOrder: 3),
  PresetCategory(name: '红包', icon: 'gift', color: '#FF8787', type: 'income', sortOrder: 4),
  PresetCategory(name: '其他', icon: 'dotsThree', color: '#FFC078', type: 'income', sortOrder: 5),
];

/// 全部预设分类（支出 + 收入）
const List<PresetCategory> allPresetCategories = [
  ...presetExpenseCategories,
  ...presetIncomeCategories,
];
