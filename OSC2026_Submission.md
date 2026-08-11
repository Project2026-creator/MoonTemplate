# OSC2026 项目申报材料：MoonTemplate

1. **项目名称**：MoonTemplate
2. **项目简介**：一个为 MoonBit 生态设计的轻量、可扩展文本模板引擎，覆盖模板解析、控制流渲染、过滤器管道和原生命令行渲染能力。
3. **项目方向与适用场景**：属于基础软件生态中的工程工具库方向，适用于静态页面生成、CLI 报表、配置文件渲染、邮件模板、代码脚手架等文本生成场景。
4. **核心能力**：
   - 自研 Lexer / Parser / AST 渲染链路
   - `{{ variable }}` 变量插值
   - `{{ variable | trim | uppercase }}` 过滤器管道
   - `{% if %} / {% else %} / {% endif %}` 条件分支
   - `{% for item in list %}` 循环渲染
   - 原生 CLI：支持模板文件和内联模板两种输入方式
5. **原创性说明**：该项目为原创实现，不是现有模板引擎的代码搬运或逐文件移植；具体说明见 `docs/source-attribution.md`。
6. **工程化说明**：
   - GitHub 与 GitLink 双远程仓库
   - GitHub Actions 与 Gitea Actions CI
   - `moon fmt --check`、`moon info`、`moon build`
   - `moon check --deny-warn`、`moon test --deny-warn`
   - `moon check --target native --deny-warn`、`moon test --target native --deny-warn`
   - 原生 CLI smoke test 与 10 次可重复基准测试（`scripts/benchmark.*`）
   - 验收自查脚本与 API 快照文件
7. **测试与边界**：覆盖变量缺失、空上下文、空迭代器、空白项、条件分支、过滤器管道、缺失块结束符、错误 CLI 参数和原生文件读取错误；CI 同时输出覆盖率摘要。
8. **GitHub 仓库**：<https://github.com/Project2026-creator/MoonTemplate>
9. **GitLink 仓库**：<https://gitlink.org.cn/Hero001/moontemplate>
