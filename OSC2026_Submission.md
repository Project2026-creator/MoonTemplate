# OSC2026 项目申报材料：MoonTemplate

## 项目简介

MoonTemplate 是面向 MoonBit 生态的原生文本模板引擎，用于生成 HTML、
邮件、配置文件、CLI 报告、提示词和代码片段等结构化文本。项目不依赖
外部模板运行时，核心实现包括 Lexer、Parser、AST、渲染器、过滤器、诊断
API、预检分析、资源限制和 native CLI。

## 核心功能与工程量

- `{{ variable }}` 插值、过滤器管线、`if/else`、`for` 循环。
- 非嵌套 `{# ... #}` 注释与 ASCII 空白控制标记。
- Unicode 安全的 `truncate`、`slice`、`length`，以及 HTML/JSON 安全输出。
- `replace`、`default`、`prefix`、`suffix`、`pad_left`、`pad_right` 等参数化过滤器。
- 结构化词法/语法/过滤器诊断，支持文本和 JSON CLI 输出。
- 模板统计、上下文依赖审计、lint 预检和输出/迭代/深度资源限制。
- 14 个真实场景基准：产品卡片、发布说明、中文本地化、CSV、日志、Markdown、
  安全输出、空值、密集循环、Unicode 边界和条件分支。

当前 `src/**/*.mbt` 超过 3,500 行，其中实现约 3,000 行、测试约 600 行；
测试与基准结果通过 CI 生成可复现证据。

## 验证方式

```text
moon fmt --check
moon info
moon build
moon check --deny-warn
moon test --deny-warn
moon check --target native --deny-warn
moon test --target native --deny-warn
```

native CLI 可运行内联模板、模板文件、变量文件、lint/stat 模式、JSON 诊断
模式和有界渲染模式。Linux/macOS 使用 `bash scripts/benchmark.sh 10`，
Windows 使用 `powershell -File scripts/benchmark.ps1 10`。

## 开源合规与仓库

项目为原创 MoonBit 实现，不复制或内置其他模板引擎源码。源码、测试、来源
说明、依赖范围和 Apache-2.0 许可证均在仓库中公开；不提交 `_build` 或本地
构建产物。

- GitHub：<https://github.com/Project2026-creator/MoonTemplate>
- GitLink：<https://gitlink.org.cn/Hero001/moontemplate>
- Mooncakes 包名：`Project2026-creator/moontemplate`
