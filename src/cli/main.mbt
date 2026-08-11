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
  diagnostics_format : DiagnosticsFormat
} derive(Debug, Eq)

///|
fn usage() -> String {
  (
    #|MoonTemplate CLI
    #|Usage:
    #|  moon run src/cli -- --file template.txt --var name=MoonBit
    #|  moon run src/cli -- --template "Hello, {{ name }}" --var name=MoonBit
    #|  moon run src/cli -- --diagnostics json --template "{{ name }}"
  )
}

///|
fn parse_cli_args(args : Array[String]) -> Result[CliOptions, String] {
  let mut template_file : String? = None
  let mut template_inline : String? = None
  let variables = []
  let mut diagnostics_format = TextDiagnostics
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
  Ok({ template_file, template_inline, variables, diagnostics_format })
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
async fn read_template_file(path : String) -> Result[String, String] {
  Ok(@fs.read_file(path).text()) catch {
    _ => Err("Unable to read template file: \{path}")
  }
}

///|
async fn render_from_options(options : CliOptions) -> Result[String, String] {
  let template = match options.template_inline {
    Some(content) => content
    None =>
      match options.template_file {
        Some(path) =>
          match read_template_file(path) {
            Ok(content) => content
            Err(message) => return Err(message)
          }
        None => return Err("Missing template input")
      }
  }
  let context = match build_context(options.variables) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let engine = match @moontemplate.Engine::new(template) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  Ok(engine.render(context))
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
  let context = match build_context(options.variables) {
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
    Err(message) => println(message)
  }
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
      diagnostics_format: TextDiagnostics,
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
    diagnostics_format: TextDiagnostics,
  }).unwrap()
  assert_eq(output, "Hello MOONBIT")
}

///|
async test "cli reports template file read errors" {
  let result = render_from_options({
    template_file: Some("__moontemplate_missing_template__.txt"),
    template_inline: None,
    variables: [],
    diagnostics_format: TextDiagnostics,
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
  assert_eq(options.diagnostics_format, JsonDiagnostics)
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
