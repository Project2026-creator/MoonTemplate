# OSC2026 项目申报材料：MoonTemplate

1. **项目名称**：MoonTemplate
2. **项目简介**：一个为 MoonBit 语言设计的轻量、灵活且可扩展的文本模板引擎。
3. **项目方向与适用场景**：属于基础软件生态的工具库方向。适用于静态网站生成器、CLI 工具动态输出格式化、后端服务文本渲染等需要动态内容生成的场景。
4. **拟实现的核心功能**：
   - 包含定制的词法分析器 (Lexer) 与语法树构建 (Parser)
   - 支持基于 `{{ variable }}` 的变量插值渲染
   - 支持基本控制流：`{% if cond %}` 条件判断与 `{% for item in list %}` 循环
   - 支持自定义过滤器/函数扩展架构 (Filter System)
   - 提供标准化的命令行执行工具 (CLI)
5. **是否为原创项目**：完全原创项目，基于 MoonBit 语法重新开发 AST 及渲染逻辑。
6. **如为移植项目**：不适用。
7. **GitHub 仓库链接**：https://github.com/Project2026-creator/MoonTemplate (包含完整的词法、语法解析、渲染、CLI与持续集成提交记录，共 20 余个有效 commit)
8. **Gitlink 仓库链接**：https://gitlink.org.cn/Hero001/moontemplate
