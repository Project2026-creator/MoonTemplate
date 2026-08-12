///|
enum DiagnosticsFormat {
  TextDiagnostics
  JsonDiagnostics
} derive(Debug, Eq)

///|
struct CliOptions {
  template_file : String?
  template_inline : String?
  variables : Array[String]
  variables_file : String?
  diagnostics_format : DiagnosticsFormat
  check_only : Bool
  show_stats : Bool
  max_output_chars : Int?
  max_iterations : Int?
  max_depth : Int?
} derive(Debug, Eq)

///|
fn usage() -> String {
  (
    #|MoonTemplate CLI
    #|Usage:
    #|  moon run src/cli -- --file template.txt --var name=MoonBit
    #|  moon run src/cli -- --template "Hello, {{ name }}" --var name=MoonBit
    #|  moon run src/cli -- --file template.txt --vars-file vars.env
    #|  moon run src/cli -- --check --stats --template "{{ name }}"
    #|  moon run src/cli -- --diagnostics json --template "{{ name }}"
    #|  Limits: --max-output N --max-iterations N --max-depth N
  )
}

///|
fn parse_cli_args(args : Array[String]) -> Result[CliOptions, String] {
  let mut template_file : String? = None
  let mut template_inline : String? = None
  let variables = []
  let mut variables_file : String? = None
  let mut diagnostics_format = TextDiagnostics
  let mut check_only = false
  let mut show_stats = false
  let mut max_output_chars : Int? = None
  let mut max_iterations : Int? = None
  let mut max_depth : Int? = None
  let mut index = 0
  while index < args.length() {
    match args[index] {
      "--help" | "-h" => return Err(usage())
      "--file" | "-f" => {
        if index + 1 >= args.length() {
          return Err("Missing value for --file")
        }
        template_file = Some(args[index + 1])
        index += 2
      }
      "--template" | "-t" => {
        if index + 1 >= args.length() {
          return Err("Missing value for --template")
        }
        template_inline = Some(args[index + 1])
        index += 2
      }
      "--var" | "-D" => {
        if index + 1 >= args.length() {
          return Err("Missing value for --var")
        }
        variables.push(args[index + 1])
        index += 2
      }
      "--vars-file" => {
        if index + 1 >= args.length() {
          return Err("Missing value for --vars-file")
        }
        variables_file = Some(args[index + 1])
        index += 2
      }
      "--check" => {
        check_only = true
        index += 1
      }
      "--stats" => {
        show_stats = true
        index += 1
      }
      "--max-output" => {
        let (value, next) = parse_cli_limit(args, index, "--max-output")
        match value {
          Ok(number) => max_output_chars = Some(number)
          Err(message) => return Err(message)
        }
        index = next
      }
      "--max-iterations" => {
        let (value, next) = parse_cli_limit(args, index, "--max-iterations")
        match value {
          Ok(number) => max_iterations = Some(number)
          Err(message) => return Err(message)
        }
        index = next
      }
      "--max-depth" => {
        let (value, next) = parse_cli_limit(args, index, "--max-depth")
        match value {
          Ok(number) => max_depth = Some(number)
          Err(message) => return Err(message)
        }
        index = next
      }
      "--diagnostics" => {
        if index + 1 >= args.length() {
          return Err("Missing value for --diagnostics")
        }
        diagnostics_format = match args[index + 1] {
          "text" => TextDiagnostics
          "json" => JsonDiagnostics
          value => return Err("Unknown diagnostics format: \{value}")
        }
        index += 2
      }
      value =>
        if template_file is None && template_inline is None {
          template_file = Some(value)
          index += 1
        } else {
          return Err("Unknown argument: \{value}")
        }
    }
  }
  if template_file is Some(_) && template_inline is Some(_) {
    return Err("Use only one of --file or --template")
  }
  if template_file is None && template_inline is None {
    return Err("Provide --file <path> or --template <text>")
  }
  Ok({
    template_file,
    template_inline,
    variables,
    variables_file,
    diagnostics_format,
    check_only,
    show_stats,
    max_output_chars,
    max_iterations,
    max_depth,
  })
}

///|
fn parse_cli_limit(
  args : Array[String],
  index : Int,
  flag : String,
) -> (Result[Int, String], Int) {
  if index + 1 >= args.length() {
    return (Err("Missing value for " + flag), index + 1)
  }
  let raw = args[index + 1]
  match parse_non_negative_int(raw) {
    Ok(value) => (Ok(value), index + 2)
    Err(_) =>
      (Err("Invalid non-negative integer for " + flag + ": " + raw), index + 2)
  }
}

///|
fn parse_non_negative_int(raw : String) -> Result[Int, Unit] {
  if raw == "" {
    return Err(())
  }
  let mut value = 0
  for c in raw {
    if !c.is_ascii_digit() {
      return Err(())
    }
    value = value * 10 + c.to_int() - '0'.to_int()
  }
  Ok(value)
}

///|
fn build_context(
  entries : Array[String],
) -> Result[Map[String, String], String] {
  let context = Map([], capacity=entries.length())
  for entry in entries {
    match entry.split_once("=") {
      Some((key, value)) if key.trim() != "" =>
        context.set(key.trim().to_owned(), value.to_owned())
      _ => return Err("Invalid --var entry: \{entry}")
    }
  }
  Ok(context)
}

///|
fn parse_variable_lines(raw : String) -> Result[Array[String], String] {
  let entries : Array[String] = []
  let mut line_number = 1
  for raw_line in raw.split("\n") {
    let line = raw_line.trim().to_owned()
    if line != "" && !line.has_prefix("#") {
      if !line.contains("=") {
        return Err(
          "Invalid variable file line " + line_number.to_string() + ": " + line,
        )
      }
      entries.push(line)
    }
    line_number += 1
  }
  Ok(entries)
}

///|
async fn read_variables_file(path : String) -> Result[Array[String], String] {
  let content = @fs.read_file(path).text() catch {
    _ => return Err("Unable to read variables file: {path}")
  }
  parse_variable_lines(content)
}

///|
async fn build_context_from_options(
  options : CliOptions,
) -> Result[Map[String, String], String] {
  let entries : Array[String] = []
  match options.variables_file {
    Some(path) => {
      let file_entries = match read_variables_file(path) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      for entry in file_entries {
        entries.push(entry)
      }
    }
    None => ()
  }
  for entry in options.variables {
    entries.push(entry)
  }
  build_context(entries)
}

///|
async fn read_template_from_options(
  options : CliOptions,
) -> Result[String, String] {
  match options.template_inline {
    Some(content) => Ok(content)
    None =>
      match options.template_file {
        Some(path) => read_template_file(path)
        None => Err("Missing template input")
      }
  }
}

///|
fn template_stats_json(stats : @moontemplate.TemplateStats) -> String {
  "{" +
  "\"node_count\":" +
  stats.node_count().to_string() +
  ",\"text_nodes\":" +
  stats.text_nodes().to_string() +
  ",\"variable_nodes\":" +
  stats.variable_nodes().to_string() +
  ",\"if_nodes\":" +
  stats.if_nodes().to_string() +
  ",\"for_nodes\":" +
  stats.for_nodes().to_string() +
  ",\"filter_count\":" +
  stats.filter_count().to_string() +
  ",\"max_depth\":" +
  stats.max_depth().to_string() +
  ",\"literal_chars\":" +
  stats.literal_chars().to_string() +
  "}"
}

///|
fn default_filter_names() -> Array[String] {
  [
    "trim", "uppercase", "lowercase", "escape_html", "escape_json", "slugify", "length",
    "collapse_whitespace", "capitalize", "newline_to_br", "replace", "truncate",
    "default", "prefix", "suffix", "pad_left", "pad_right", "slice",
  ]
}

///|
async fn check_template_from_options(
  options : CliOptions,
) -> Result[String, String] {
  let template = match read_template_from_options(options) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  match @moontemplate.lint_template(template, default_filter_names()) {
    Err(diagnostics) => Err(diagnostic_text(diagnostics[0]))
    Ok(issues) => {
      let mut output = "Template check passed"
      for issue in issues {
        output += "\n" + issue.code() + ": " + issue.message()
      }
      Ok(output)
    }
  }
}

///|
fn diagnostic_text(diagnostic : @moontemplate.Diagnostic) -> String {
  "\{diagnostic.code()} at \{diagnostic.line()}:\{diagnostic.column()}: \{diagnostic.message()}"
}

///|
fn render_failure_text(failure : @moontemplate.RenderFailure) -> String {
  match failure {
    @moontemplate.OutputLimitExceeded(limit, actual) =>
      "Output limit exceeded: limit=" +
      limit.to_string() +
      ", current=" +
      actual.to_string()
    @moontemplate.IterationLimitExceeded(limit) =>
      "Iteration limit exceeded: limit=" + limit.to_string()
    @moontemplate.DepthLimitExceeded(limit) =>
      "Render depth limit exceeded: limit=" + limit.to_string()
  }
}

///|
async fn read_template_file(path : String) -> Result[String, String] {
  Ok(@fs.read_file(path).text()) catch {
    _ => Err("Unable to read template file: \{path}")
  }
}

///|
async fn render_from_options(options : CliOptions) -> Result[String, String] {
  let template = match read_template_from_options(options) {
    Ok(content) => content
    Err(message) => return Err(message)
  }
  let context = match build_context_from_options(options) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let engine = match @moontemplate.Engine::new(template) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  match (options.max_output_chars, options.max_iterations, options.max_depth) {
    (None, None, None) => Ok(engine.render(context))
    _ => {
      let defaults = @moontemplate.RenderLimits::default()
      let limits = @moontemplate.RenderLimits::new(
        options.max_output_chars.unwrap_or(defaults.max_output_chars()),
        options.max_iterations.unwrap_or(defaults.max_iterations()),
        options.max_depth.unwrap_or(defaults.max_depth()),
      )
      match engine.render_with_limits(context, limits) {
        Ok(report) => Ok(report.output())
        Err(failure) => Err(render_failure_text(failure))
      }
    }
  }
}

///|
pub fn escape_json_string(value : String) -> String {
  let mut escaped = ""
  for c in value {
    escaped += match c {
      '"' => "\\\""
      '\\' => "\\\\"
      '\n' => "\\n"
      '\r' => "\\r"
      '\t' => "\\t"
      _ => c.to_string()
    }
  }
  escaped
}

///|
pub fn diagnostic_json(diagnostic : @moontemplate.Diagnostic) -> String {
  let quote = fn(value : String) -> String {
    "\"" + escape_json_string(value) + "\""
  }
  "{\"code\":" +
  quote(diagnostic.code()) +
  "," +
  "\"kind\":" +
  quote(diagnostic.kind().as_str()) +
  "," +
  "\"message\":" +
  quote(diagnostic.message()) +
  "," +
  "\"line\":" +
  diagnostic.line().to_string() +
  "," +
  "\"column\":" +
  diagnostic.column().to_string() +
  "," +
  "\"source_line\":" +
  quote(diagnostic.source_line()) +
  "}"
}

///|
pub async fn render_with_diagnostics(
  options : CliOptions,
) -> Result[String, Array[@moontemplate.Diagnostic]] {
  let template = match options.template_inline {
    Some(content) => content
    None =>
      match options.template_file {
        Some(path) =>
          match read_template_file(path) {
            Ok(content) => content
            Err(message) =>
              return Err([
                @moontemplate.Diagnostic::new(
                  @moontemplate.DiagnosticKind::Lexical,
                  message,
                  0,
                  0,
                  "",
                ),
              ])
          }
        None =>
          return Err([
            @moontemplate.Diagnostic::new(
              @moontemplate.DiagnosticKind::Syntax,
              "Missing template input",
              0,
              0,
              "",
            ),
          ])
      }
  }
  let context = match build_context_from_options(options) {
    Ok(value) => value
    Err(message) =>
      return Err([
        @moontemplate.Diagnostic::new(
          @moontemplate.DiagnosticKind::Syntax,
          message,
          0,
          0,
          "",
        ),
      ])
  }
  let engine = match @moontemplate.Engine::new_with_diagnostics(template) {
    Ok(value) => value
    Err(diagnostics) => return Err(diagnostics)
  }
  engine.render_strict(context)
}

///|
async fn main {
  let args = @env.args()[1:].to_owned()
  match parse_cli_args(args) {
    Ok(options) =>
      if options.check_only {
        match check_template_from_options(options) {
          Ok(output) => println(output)
          Err(message) => println("Error: \{message}")
        }
      } else if options.show_stats {
        match stats_from_options(options) {
          Ok(output) => println(output)
          Err(message) => println("Error: \{message}")
        }
      } else {
        match options.diagnostics_format {
          TextDiagnostics =>
            match render_from_options(options) {
              Ok(output) => println(output)
              Err(message) => println("Error: \{message}\n\n\{usage()}")
            }
          JsonDiagnostics =>
            match render_with_diagnostics(options) {
              Ok(output) => println(output)
              Err(diagnostics) => println(diagnostic_json(diagnostics[0]))
            }
        }
      }
    Err(message) => println(message)
  }
}

///|
async fn stats_from_options(options : CliOptions) -> Result[String, String] {
  let template = match read_template_from_options(options) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let engine = match @moontemplate.Engine::new(template) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  Ok(template_stats_json(engine.stats()))
}

///|
test "cli argument parser supports file and vars" {
  let parsed = parse_cli_args([
    "--file", "template.txt", "--var", "name=MoonBit",
  ]).unwrap()
  assert_true(
    parsed ==
    {
      template_file: Some("template.txt"),
      template_inline: None,
      variables: ["name=MoonBit"],
      variables_file: None,
      diagnostics_format: TextDiagnostics,
      check_only: false,
      show_stats: false,
      max_output_chars: None,
      max_iterations: None,
      max_depth: None,
    },
  )
}

///|
test "cli context parser rejects malformed vars" {
  match build_context(["broken"]) {
    Err(message) => assert_eq(message, "Invalid --var entry: broken")
    Ok(_) => fail("Expected malformed variable assignment to fail")
  }
}

///|
test "cli rejects conflicting template inputs" {
  match parse_cli_args(["--file", "template.txt", "--template", "Hello"]) {
    Err(message) => assert_eq(message, "Use only one of --file or --template")
    Ok(_) => fail("Expected conflicting template inputs to fail")
  }
}

///|
test "cli rejects unknown arguments after a template" {
  match parse_cli_args(["--template", "Hello", "--unknown"]) {
    Err(message) => assert_eq(message, "Unknown argument: --unknown")
    Ok(_) => fail("Expected unknown argument to fail")
  }
}

///|
async test "cli renders inline templates" {
  let output = render_from_options({
    template_file: None,
    template_inline: Some("Hello {{ name | uppercase }}"),
    variables: ["name=moonbit"],
    variables_file: None,
    diagnostics_format: TextDiagnostics,
    check_only: false,
    show_stats: false,
    max_output_chars: None,
    max_iterations: None,
    max_depth: None,
  }).unwrap()
  assert_eq(output, "Hello MOONBIT")
}

///|
async test "cli reports template file read errors" {
  let result = render_from_options({
    template_file: Some("__moontemplate_missing_template__.txt"),
    template_inline: None,
    variables: [],
    variables_file: None,
    diagnostics_format: TextDiagnostics,
    check_only: false,
    show_stats: false,
    max_output_chars: None,
    max_iterations: None,
    max_depth: None,
  })
  match result {
    Err(message) =>
      assert_true(message.contains("Unable to read template file"))
    Ok(_) => fail("Expected missing template file to return an error")
  }
}

///|
test "cli accepts JSON diagnostics mode" {
  let options = parse_cli_args(["--diagnostics", "json", "--template", "Hello"]).unwrap()
  assert_true(options.diagnostics_format == JsonDiagnostics)
}

///|
async test "cli JSON diagnostics contain stable fields" {
  let options = parse_cli_args([
    "--diagnostics", "json", "--template", "{{ broken",
  ]).unwrap()
  match render_with_diagnostics(options) {
    Err(diagnostics) => {
      let json = diagnostic_json(diagnostics[0])
      assert_true(json.contains("\"code\":\"TMPL_PARSE\""))
      assert_true(json.contains("\"kind\":\"syntax\""))
      assert_true(json.contains("\"line\":1"))
      assert_true(json.contains("\"source_line\""))
    }
    Ok(_) => fail("Expected JSON diagnostic rendering to fail")
  }
}

///|
test "cli supports reusable variable files and audit flags" {
  let options = parse_cli_args([
    "--template", "Hello", "--vars-file", "vars.env", "--check", "--stats", "--max-output",
    "120", "--max-iterations", "5", "--max-depth", "3",
  ]).unwrap()
  assert_true(options.variables_file == Some("vars.env"))
  assert_true(options.check_only)
  assert_true(options.show_stats)
  assert_true(options.max_output_chars == Some(120))
  assert_true(options.max_iterations == Some(5))
  assert_true(options.max_depth == Some(3))
}

///|
test "cli variable file parser ignores comments and blank lines" {
  let entries = parse_variable_lines(
    "# generated values\nname=MoonBit\n\ncount=3\n",
  ).unwrap()
  assert_eq(entries.length(), 2)
  assert_eq(entries[0], "name=MoonBit")
  assert_eq(entries[1], "count=3")
}

///|
test "cli variable file parser rejects malformed active lines" {
  match parse_variable_lines("name=MoonBit\nbroken\n") {
    Err(message) => assert_true(message.contains("line 2"))
    Ok(_) => fail("Expected malformed variable file line")
  }
}

///|
test "cli stats JSON exposes stable runtime fields" {
  let engine = @moontemplate.Engine::new("Hi {{ name }}").unwrap()
  let stats = engine.stats()
  let json = template_stats_json(stats)
  assert_true(json.contains("\"node_count\":2"))
  assert_true(json.contains("\"variable_nodes\":1"))
  assert_true(json.contains("\"literal_chars\":3"))
}
