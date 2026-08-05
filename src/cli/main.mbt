///|
struct CliOptions {
  template_file : String?
  template_inline : String?
  variables : Array[String]
} derive(Debug, Eq)

///|
fn usage() -> String {
  (
    #|MoonTemplate CLI
    #|Usage:
    #|  moon run src/cli -- --file template.txt --var name=MoonBit
    #|  moon run src/cli -- --template "Hello, {{ name }}" --var name=MoonBit
  )
}

///|
fn parse_cli_args(args : Array[String]) -> Result[CliOptions, String] {
  let mut template_file : String? = None
  let mut template_inline : String? = None
  let variables = []
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
      value =>
        if template_file is None {
          template_file = Some(value)
          index += 1
        } else {
          return Err("Unknown argument: \{value}")
        }
    }
  }
  if template_file is None && template_inline is None {
    return Err("Provide --file <path> or --template <text>")
  }
  Ok({ template_file, template_inline, variables })
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
async fn main {
  let args = @env.args()[1:].to_owned()
  match parse_cli_args(args) {
    Ok(options) =>
      match render_from_options(options) {
        Ok(output) => println(output)
        Err(message) => println("Error: \{message}\n\n\{usage()}")
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
async test "cli renders inline templates" {
  let output = render_from_options({
    template_file: None,
    template_inline: Some("Hello {{ name | uppercase }}"),
    variables: ["name=moonbit"],
  }).unwrap()
  assert_eq(output, "Hello MOONBIT")
}

///|
async test "cli reports template file read errors" {
  let result = render_from_options({
    template_file: Some("__moontemplate_missing_template__.txt"),
    template_inline: None,
    variables: [],
  })
  match result {
    Err(message) =>
      assert_true(message.contains("Unable to read template file"))
    Ok(_) => fail("Expected missing template file to return an error")
  }
}
