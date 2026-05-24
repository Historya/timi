# Pencil Design Specs for All Pages

## 1. Voice Input (Device Frame 2, `mH0UD`)
- Status Bar: 9:41 time, wifi-high + battery icons
- Close Button: top-right, 40×40, glass circle, `x` icon
- Spacer flex
- **Voice Center Area** (centered):
  - 4 concentric ellipses (180/160/130 dia) + mic icon (48×48, phosphor `microphone`)
  - Container: 220×220, glass with border, backdrop blur
  - Status text: "正在聆听..." 20px bold
  - Sub text: "说出你的记账内容" 14px normal
- **Recognized Text Glass**: 
  - Label "识别结果" 12px
  - Text "午餐消费 38 元" 18px bold, centered
  - Container: glass, radius 16, padding 16
- **Action Buttons** (centered row):
  - Cancel: 120×48, "取消" 15px, glass border
  - Confirm: 140×48, "✓ 确认添加" 15px bold, glass with blur
  - gap: 16
- bottom spacer flex

## 2. Bills (Device Frame 3, `i2mDm`)
- Status Bar (same pattern)
- **Header**: "账单明细" 22px bold + search btn (40×40, circle, magnifying-glass)
- **Month Selector**: < 2026年5月 > with caret-left/right buttons (36×36)
- **Monthly Summary Glass**: horizontal, income ¥32,450 / expense ¥18,230, divider line
- **Bill List**: Date groups ("今天"/"昨天"), each with Bill Item Glass cards (icon+name+time+amount)
- **Tab Bar**: pill style, Bills tab highlighted

## 3. Statistics (Device Frame 4, `EOR6H`)
- **Header**: "支出统计" 22px bold + period btn "本月" 80×36
- **Overview Glass Card**: "本月总支出" / "¥ 18,230" 34px / "↑12.5%" red
- **Chart Glass Card**: 7 bar chart columns (Mon-Sun) with day labels
- **Category Glass Card**: 5 categories with progress bars
- **Tab Bar**: Stats tab highlighted

## 4. Add Transaction (Device Frame 5, `ktfkX`)
- **Header**: "取消" - "添加支出" - "完成" (3-column)
- **Type Toggle**: 支出/收入 segmented control
- **Amount Card**: amount input area with numeric pad quick buttons
- **Category Grid**: 2 rows × 4 cols (餐饮/交通/购物/娱乐/医疗/教育/居家/其他)
- **Note Input**: glass with note icon + placeholder
- **Save Button**: full-width glass button

## 5. Profile (Device Frame 6, `f1OAxk`)
- **Header**: "我的" 22px bold + gear icon
- **User Info**: avatar (80×80, user icon) + "用户昵称" + "设置你的个人资料"
- **Stats Row**: 3 stats in glass card (no detail in read - but has stat items)
- **Menu Card**: 5 rows in glass card (分类管理, 预算设置, 数据导出, 设置, 关于) with icons and carets
- **Tab Bar**: Profile tab highlighted

## 6. Bill Detail (Device Frame 7, `r1sbkG`)
- **Header**: back arrow + "账单详情" + dots menu
- **Icon Area**: centered category icon (72×72) with colored background
- **Amount**: "-¥328.50" 36px bold red
- **Category Label**: "超市购物" subtitle
- **Detail Card**: 分类/日期/账户 rows with separators
- **Note Card**: note icon + text
- **Voice Note Card**: play icon + "语音备注" + duration "0:03"
- **Action Buttons**: "删除" (red outline) + "编辑" (glass filled)

## 7. Categories (Device Frame 8, `xSMeP`)
- **Header**: back + "分类管理" + plus button (36×36)
- **Type Toggle**: 支出分类/收入分类
- **Hint text**: "长按拖动排序 · 点击编辑"
- **Category Grid Glass**: 3 rows × 3 cols of category items with icon+name
- **Income Category Section**: separate section with same grid style
- **Tab Bar**

## 8. Search (Device Frame 9, `ZDItk`)
- **Header**: back + "搜索"
- **Search Bar**: magnifying-glass + placeholder "搜索交易、分类..." + clear button
- **Filter Chips**: 全部(active), 支出, 收入, 餐饮
- **Results Section**: date labels + result items (icon + name/category + amount)

## 9. Settings (Device Frame 10, `e1dRy`)
- **Header**: back + "设置"
- **Voice Section**: "语音识别" section label
  - Card with rows: 离线引擎→系统引擎, 云端引擎→百度
- **Data Section**: "数据管理" section label
  - Card with rows: 默认货币→人民币¥, 默认分类→餐饮, 预算提醒→toggle
- **Display Section**: "显示" section label
  - Card with rows: 深色模式→toggle, 语言→简体中文

## 10. Budget (Device Frame 11, `F46yr`)
- **Header**: back + "预算设置"
- **Budget Overview Card**: 月度预算, ¥3,000.00 + edit pencil, progress bar, spent/remaining stats
- **Category Budget Card**: 4 categories with progress bars (餐饮/交通/购物/娱乐)

## 11. Export (Device Frame 12, `mI5iy`)
- **Header**: back + "数据导出"
- **Date Range Card**: calendar icon + "2026年1月 - 2026年5月" + caret
- **Export Content Card**: radio buttons (所有交易/仅支出/仅收入)
- **Format Card**: radio buttons (CSV/PDF)
- **Export Button**: download icon + "导出并分享"

## 12. About (Device Frame 13, `y54ONk`)
- **Header**: back + "关于"
- **App Icon Area**: 80×80 app icon (currency-circle-dollar) + "Timi" + "v1.0.0" + tagline "极简语音记账"
- **Menu Card**: 更新日志/用户协议/隐私政策 rows with carets
- **Copyright**: "(c) 2024 Timi Team"

## 13. Edit Category (Device Frame 14, `joLmr`)
- **Modal Overlay**: semi-transparent background
- **Modal Card**: 
  - Header: "编辑分类" / "新建分类" with close
  - Icon Grid: grid of selectable icons
  - Name Input: glass input field
  - Color Picker: row of color circles
  - Button Row: cancel + save
