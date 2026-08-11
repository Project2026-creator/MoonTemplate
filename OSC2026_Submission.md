# OSC2026 项目申报材料：MoonTemplate

## 项目简介

MoonTemplate 是面向 MoonBit 生态的轻量文本模板引擎，使用 MoonBit 原生
实现 Lexer、Parser、AST、渲染器、过滤器管线和 native CLI。项目面向静态
页面、CLI 报表、配置/清单、通知文本和代码脚手架等可复现的结构化文本生成
场景，不依赖外部模板运行时。

## 核心功能

- `{{ variable }}` 插值、缺失变量空字符串语义和 `if/else`、`for` 控制流。
- `trim`、大小写转换、HTML/JSON 转义、`slugify` 等内置过滤器。
- `replace("old", "new")`、Unicode 字符数 `truncate(20)`、空白感知
  `default("fallback")` 参数化过滤器。
- `{# ... #}` 非嵌套注释和 `{{-`、`-}}`、`{%-`、`-%}` ASCII 空白控制。
- 严格诊断 API：词法、语法、过滤器类别，1-based 行列号和源码行。
- CLI 支持文件/内联模板、重复 `--var key=value` 和 `--diagnostics text|json`。

## 工程与验证

仓库包含公开 MoonBit 源码、30 个库测试、CLI 测试、边界测试、覆盖率摘要、
native smoke test、可重复 benchmark、API 快照和双平台 CI。验证命令包括：

```text
moon fmt --check
moon info
moon build
moon check --deny-warn
moon check --target native --deny-warn
moon test --deny-warn
moon test --target native --deny-warn
```

GitHub 仓库：<https://github.com/Project2026-creator/MoonTemplate>

GitLink 仓库：<https://gitlink.org.cn/Hero001/moontemplate>

## 原创与开源合规

项目为原创 MoonBit 实现，不复制或移植其他模板引擎源码。来源、第三方依赖、
许可证和贡献规则分别记录在 `docs/source-attribution.md`、`LICENSE` 和
`CONTRIBUTING.md` 中，发布包版本与仓库版本保持一致。
