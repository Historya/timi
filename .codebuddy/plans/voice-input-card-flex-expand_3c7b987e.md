---
name: voice-input-card-flex-expand
overview: 账目卡片轮播改为弹性布局：底部确认/取消按钮行固定高度，轮播卡片 Expanded 占满页面剩余空间，卡片内部备注区随卡片高度自动伸展。
todos:
  - id: flex-carousel-layout
    content: expense_card_carousel.dart 改为 Expanded(PageView) 占满 + 圆点指示器固定，删除固定 430 高度
    status: completed
  - id: flex-result-layout
    content: voice_input_screen.dart 结果态去 SingleChildScrollView，改 Column+Expanded 轮播+固定操作行
    status: completed
    dependencies:
      - flex-carousel-layout
  - id: analyze-validate
    content: 运行 flutter analyze 验证无新增问题
    status: completed
    dependencies:
      - flex-result-layout
---

## 需求概述
语音输入页结果态的账目卡片仍显太小，改为 flex 弹性布局：
- **上下固定、中间占满**：顶部关闭按钮、底部"确认/取消"操作行保持固定高度；中间卡片轮播区域通过 `Expanded` 占满剩余全部空间，卡片随屏幕高度自动放大
- 卡片内部已是 flex 结构（顶行/金额/类型/日期固定高，备注区 `Expanded` 弹性），卡片变大时备注区自然伸展，无需改动
- 3D 层叠轮播、圆点指示器、卡片内编辑实时回写等既有交互全部保持不变


## 技术方案
仅改 2 个文件的布局外壳，不动卡片内容与状态逻辑：

1. **`lib/ui/voice_input/widgets/expense_card_carousel.dart`** [MODIFY]
   - `build` 中删掉固定高度包裹 `SizedBox(height: 430)`，改为 `Column > [Expanded(child: PageView.builder), 圆点指示器(固定高, 仅多笔显示)]`
   - PageView 需有界高度，由外部调用处的 Expanded 提供约束（组件语义从"固定高"变为"填满父容器"，唯一调用处同步修改）

2. **`lib/ui/voice_input/voice_input_screen.dart`** [MODIFY]
   - `_buildResultLayout` 去掉 `SingleChildScrollView`（改用 flex 后内容自适应视口，不再需要滚动），改为：
     `Column > [Expanded(ExpenseCardCarousel), SizedBox(16), Row(确认按钮 52px + 取消按钮 48px 固定高), SizedBox(8)]`
   - 页面骨架已有 `Expanded > Center > ConstrainedBox(600) > switch(四态)`，Column 在受限高度内正常撑满

## 风险与对策
- **键盘弹出**：Scaffold 默认 `resizeToAvoidBottomInset: true`，键盘弹出时 Expanded 区域自动压缩，卡片备注区（minLines=1）可收缩，无溢出；比原固定 430 + SingleChildScrollView 对键盘更友好
- **极小屏幕**：Expanded 被压缩时卡片内容仍可收缩至备注单行，不崩布局
- 单笔账目（count == 1）时 Expanded 同样生效，卡片居中撑满

## 验证
`flutter analyze` 0 新增问题（既有 dashscope_semantic_parser.dart 的 empty_catches info 不处理）
	
