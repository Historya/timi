# Timi 项目文档索引

本目录存放项目的详细开发文档。快速了解项目请看根目录 [README.md](../README.md),AI 代理工作规范见根目录 [AGENTS.md](../AGENTS.md)。

## 文档目录

| 文档 | 内容 |
|------|------|
| [architecture.md](architecture.md) | 应用架构、数据流、路由表、目录结构 |
| [database.md](database.md) | 数据库表结构、DAO、命名约定、迁移 |
| [services.md](services.md) | ASR 语音识别、AI 语义解析、解析降级管线 |
| [theme-design.md](theme-design.md) | 暗色玻璃拟态主题、共享组件 |
| [conventions.md](conventions.md) | 代码规范、页面模式、错误处理、测试与 QA |

## 参考资料目录

| 目录 | 内容 |
|------|------|
| `agent/` | 设计规格说明 (design-specs.md, 各页面 UI 规格) |
| `ui-design/` | UI 原型 (Pencil ui.pen + gauge.js) |
| `tx_asr/` | 腾讯云 ASR 接口文档快照 (index.html) |
| `script/` | 辅助脚本 (check_chinese.py, 检查中文注释编码) |

## 常用命令

```bash
flutter analyze                          # 代码分析 (要求 0 error, 0 warning)
flutter test                             # 运行测试
flutter pub get                          # 安装依赖
flutter pub run build_runner build --delete-conflicting-outputs  # drift 代码生成
flutter pub run build_runner watch       # 自动重建
```
