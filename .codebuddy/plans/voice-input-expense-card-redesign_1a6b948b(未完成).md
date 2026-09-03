---
name: voice-input-expense-card-redesign
overview: 重构语音输入页结果态的账目展示：单笔/多笔统一显示精美毛玻璃卡片，多笔时用 PageView 实现左右滑动切换（卡包式轮播），滑动同步下方编辑表单，配页码圆点指示器。仅改动 voice_input_screen.dart。
todos:
  - id: restyle-expense-card
    content: 重设计 _buildExpenseCard：分类图标圆标、金额/日期/备注布局、选中态高亮与未选中弱化
    status: pending
  - id: pageview-carousel
    content: 新增 PageController，_buildExpenseCardList 改为 PageView 轮播（onPageChanged 同步表单、指示器圆点、删除/确认后 animateToPage、dispose 释放）
    status: pending
  - id: analyze-validate
    content: 运行 flutter analyze 验证 0 错误 0 警告
    status: pending
---

## 需求概述
优化语音记账结果页的账目卡片体验（lib/ui/voice_input/voice_input_screen.dart）：

## 核心功能
- **卡片风格重设计**：将现有简陋的 160×112 简易卡片升级为更精致的毛玻璃卡片——展示分类图标（按分类颜色着色的圆形图标底）、分类名、金额（收入/支出区分配色）、备注、解析日期（非今天时显示）；选中卡片高亮（accentBlue 描边 + accent 填充），未选中卡片弱化显示
- **左右滑动切换**：多笔账目时卡片改为 PageView 轮播（露边效果，viewportFraction≈0.85），支持手势左右滑动翻页；滑动或点击卡片均同步刷新下方编辑表单（复用已有 `_syncFormFromIndex`）
- **删除/确认联动**：单笔确认或取消某张卡片后，列表自动平滑滚动到新的当前卡片；全部处理完保持原有回退/弹回逻辑不变
- **统一呈现**：结果态始终以卡片形式展示解析结果（单笔显示单张居中卡片 + 编辑表单）

## 技术方案
- **框架**：Flutter（Dart），沿用 Riverpod + 现有 AppTheme 毛玻璃体系，仅改动 `lib/ui/voice_input/voice_input_screen.dart` 单文件
- **轮播实现**：`PageView.builder` + `PageController(viewportFraction: 0.85)` 替换现有横向 `ListView.separated`（`_buildExpenseCardList`，L1061）；固定高度 SizedBox 包裹
- **表单同步**：`onPageChanged` 中 `index != _selectedExpenseIndex` 时调用 `_syncFormFromIndex(index)`，避免 `animateToPage` 过程中重复同步覆盖用户正在编辑的表单
- **删除联动**：新增 `_scrollPageToSelected()`，内部以 `_pageController.hasClients` 守卫后 `animateToPage` 到 `_selectedExpenseIndex`；在 `_removeExpenseFromList`/`_confirmSingleExpense` 成功路径后调用
- **卡片视觉**：`AnimatedContainer` + 现有 `glassFill/glassFillStrong/glassFillAccent/glassStroke` 配色；分类图标通过 `resolveCategoryIcon`（lib/ui/shared/icon_helpers.dart）渲染，分类颜色由 `allCategoriesProvider` 按名称匹配后 `parseHexColor` 解析；AI 推荐新分类回退 `dotsThree` 图标 + `#69DB7C`（与 `_saveTransaction` 自动建类逻辑一致）
- **资源管理**：新增 `PageController` 字段，`dispose()` 中释放；l10n 复用现有 key（uncategorized 等），不新增 ARB 条目

## 涉及文件
```
lib/ui/voice_input/voice_input_screen.dart  # [MODIFY] 唯一改动文件
```

## 潜在风险
- `animateToPage` 在列表缩短后需 `hasClients` 守卫，避免移除最后一张卡时异常
- PageView 高度增加会挤占表单空间，结果态已是 SingleChildScrollView 可滚动，无溢出风险
- 滑动切换会以解析值覆盖表单（与现有点击行为一致），保持既有语义不引入额外状态
