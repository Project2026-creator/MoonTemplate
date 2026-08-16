///|
/// A deterministic workload used for regression and acceptance evidence.
pub struct BenchmarkCase {
  name : String
  category : String
  description : String
  template : String
  context_entries : Array[(String, String)]
  expected_output : String
  limits : RenderLimits
} derive(Debug, Eq)

///|
pub fn BenchmarkCase::name(self : BenchmarkCase) -> String {
  self.name
}

///|
pub fn BenchmarkCase::category(self : BenchmarkCase) -> String {
  self.category
}

///|
pub fn BenchmarkCase::description(self : BenchmarkCase) -> String {
  self.description
}

///|
pub fn BenchmarkCase::template(self : BenchmarkCase) -> String {
  self.template
}

///|
pub fn BenchmarkCase::expected_output(self : BenchmarkCase) -> String {
  self.expected_output
}

///|
pub fn BenchmarkCase::limits(self : BenchmarkCase) -> RenderLimits {
  self.limits
}

///|
pub fn BenchmarkCase::context(self : BenchmarkCase) -> Map[String, String] {
  let context : Map[String, String] = Map(
    [],
    capacity=self.context_entries.length(),
  )
  for entry in self.context_entries {
    let (key, value) = entry
    context.set(key, value)
  }
  context
}

///|
/// Metrics and expected-output evidence for one workload.
pub struct BenchmarkResult {
  name : String
  category : String
  passed : Bool
  output_chars : Int
  expected_chars : Int
  nodes_visited : Int
  iterations : Int
  unicode_chars : Int
  missing_variables : Int
} derive(Debug, Eq)

///|
pub fn BenchmarkResult::name(self : BenchmarkResult) -> String {
  self.name
}

///|
pub fn BenchmarkResult::category(self : BenchmarkResult) -> String {
  self.category
}

///|
pub fn BenchmarkResult::passed(self : BenchmarkResult) -> Bool {
  self.passed
}

///|
pub fn BenchmarkResult::output_chars(self : BenchmarkResult) -> Int {
  self.output_chars
}

///|
pub fn BenchmarkResult::expected_chars(self : BenchmarkResult) -> Int {
  self.expected_chars
}

///|
pub fn BenchmarkResult::nodes_visited(self : BenchmarkResult) -> Int {
  self.nodes_visited
}

///|
pub fn BenchmarkResult::iterations(self : BenchmarkResult) -> Int {
  self.iterations
}

///|
pub fn BenchmarkResult::unicode_chars(self : BenchmarkResult) -> Int {
  self.unicode_chars
}

///|
pub fn BenchmarkResult::missing_variables(self : BenchmarkResult) -> Int {
  self.missing_variables
}

///|
/// The acceptance workload catalog. Inputs are deliberately small and readable.
pub fn benchmark_cases() -> Array[BenchmarkCase] {
  [
    {
      name: "greeting",
      category: "basic",
      description: "Trim a user name and render a short greeting",
      template: "Hello, {{ name | trim }}!",
      context_entries: [("name", " MoonBit ")],
      expected_output: "Hello, MoonBit!",
      limits: RenderLimits::new(200, 10, 4),
    },
    {
      name: "product-card",
      category: "web",
      description: "Escape a title and prefix a display price",
      template: "<article><h1>{{ title | escape_html }}</h1><p>{{ price | prefix(\"$\") }}</p></article>",
      context_entries: [("title", "MoonBit <Template>"), ("price", "9.90")],
      expected_output: "<article><h1>MoonBit &lt;Template&gt;</h1><p>$9.90</p></article>",
      limits: RenderLimits::new(400, 10, 4),
    },
    {
      name: "release-notes",
      category: "documentation",
      description: "Render a release heading and a bullet list",
      template: "## {{ version }}\n{% for item in changes %}- {{ item | trim }}\n{% endfor %}",
      context_entries: [("version", "0.2.6"), ("changes", "Lexer, Parser, CLI")],
      expected_output: "## 0.2.6\n- Lexer\n- Parser\n- CLI\n",
      limits: RenderLimits::new(400, 10, 4),
    },
    {
      name: "localization-cn",
      category: "i18n",
      description: "Render a Unicode greeting without byte-based slicing",
      template: "{{ greeting }}，{{ name }}！",
      context_entries: [("greeting", "你好"), ("name", "月亮")],
      expected_output: "你好，月亮！",
      limits: RenderLimits::new(100, 10, 4),
    },
    {
      name: "csv-row",
      category: "data",
      description: "Create a stable CSV-like row with an escaped field",
      template: "{{ id | pad_left(4, \"0\") }},{{ name | escape_json }}",
      context_entries: [("id", "7"), ("name", "Li, Ping")],
      expected_output: "0007,\"Li, Ping\"",
      limits: RenderLimits::new(100, 10, 4),
    },
    {
      name: "audit-log",
      category: "operations",
      description: "Normalize a log message and preserve a level prefix",
      template: "[{{ level | uppercase }}] {{ message | collapse_whitespace }}",
      context_entries: [
        ("level", "warn"),
        ("message", "  slow\n request\tfrom edge  "),
      ],
      expected_output: "[WARN] slow request from edge",
      limits: RenderLimits::new(200, 10, 4),
    },
    {
      name: "markdown-heading",
      category: "documentation",
      description: "Build a slugged heading and HTML-safe line breaks",
      template: "# {{ title | slugify }}\n{{ body | newline_to_br }}",
      context_entries: [
        ("title", "MoonBit API Guide"),
        ("body", "first\nsecond"),
      ],
      expected_output: "# moonbit-api-guide\nfirst<br>second",
      limits: RenderLimits::new(300, 10, 4),
    },
    {
      name: "semicolon-list",
      category: "composition",
      description: "Compose a prefix and suffix inside a loop",
      template: "{{ prefix }}{% for item in items %}{{ item | suffix(\";\") }}{% endfor %}",
      context_entries: [("prefix", "items:"), ("items", "red,green,blue")],
      expected_output: "items:red;green;blue;",
      limits: RenderLimits::new(200, 10, 4),
    },
    {
      name: "empty-values",
      category: "boundary",
      description: "Use explicit fallbacks for missing and whitespace-only values",
      template: "{{ missing | default(\"fallback\") }}|{{ blank | default(\"fallback\") }}",
      context_entries: [("blank", "   ")],
      expected_output: "fallback|fallback",
      limits: RenderLimits::new(100, 10, 4),
    },
    {
      name: "dense-catalog",
      category: "stress",
      description: "Render a dense repeated catalog under an iteration budget",
      template: "{% for item in items %}<li>{{ item | trim }}</li>{% endfor %}",
      context_entries: [("items", "alpha,beta,gamma,delta,epsilon")],
      expected_output: "<li>alpha</li><li>beta</li><li>gamma</li><li>delta</li><li>epsilon</li>",
      limits: RenderLimits::new(500, 10, 4),
    },
    {
      name: "secure-output",
      category: "security",
      description: "Escape untrusted markup before an HTML response",
      template: "<p>{{ body | escape_html }}</p>",
      context_entries: [("body", "<script>alert(1)</script>")],
      expected_output: "<p>&lt;script&gt;alert(1)&lt;/script&gt;</p>",
      limits: RenderLimits::new(300, 10, 4),
    },
    {
      name: "unicode-slice",
      category: "boundary",
      description: "Select two Unicode characters by character index",
      template: "{{ title | slice(1, 2) }}",
      context_entries: [("title", "模板引擎")],
      expected_output: "板引",
      limits: RenderLimits::new(100, 10, 4),
    },
    {
      name: "short-summary",
      category: "boundary",
      description: "Truncate a summary by Unicode character count",
      template: "{{ summary | truncate(12) }}...",
      context_entries: [("summary", "MoonBit template rendering")],
      expected_output: "MoonBit temp...",
      limits: RenderLimits::new(200, 10, 4),
    },
    {
      name: "conditional-banner",
      category: "control-flow",
      description: "Select a branch from a conventional boolean string",
      template: "{% if enabled %}enabled: {{ name }}{% else %}disabled{% endif %}",
      context_entries: [("enabled", "true"), ("name", "MoonTemplate")],
      expected_output: "enabled: MoonTemplate",
      limits: RenderLimits::new(200, 10, 4),
    },
  ]
}

///|
pub fn run_benchmark_case(
  item : BenchmarkCase,
) -> Result[BenchmarkResult, String] {
  let engine = match Engine::new(item.template) {
    Ok(value) => value
    Err(message) =>
      return Err("Benchmark parse failed for " + item.name + ": " + message)
  }
  let report = match engine.render_with_limits(item.context(), item.limits) {
    Ok(value) => value
    Err(failure) =>
      return Err(
        "Benchmark limit failed for " + item.name + ": " + failure_text(failure),
      )
  }
  let output = report.output()
  let metrics = report.metrics()
  Ok({
    name: item.name,
    category: item.category,
    passed: output == item.expected_output,
    output_chars: output.char_length(),
    expected_chars: item.expected_output.char_length(),
    nodes_visited: metrics.nodes_visited(),
    iterations: metrics.iterations(),
    unicode_chars: count_unicode(output),
    missing_variables: metrics.missing_variables(),
  })
}

///|
pub fn run_benchmark_suite() -> Result[Array[BenchmarkResult], String] {
  let results : Array[BenchmarkResult] = []
  for item in benchmark_cases() {
    match run_benchmark_case(item) {
      Ok(result) => results.push(result)
      Err(message) => return Err(message)
    }
  }
  Ok(results)
}

///|
/// Serialize one result with stable keys for CI artifacts.
pub fn BenchmarkResult::to_json(self : BenchmarkResult) -> String {
  "{" +
  "\"name\":" +
  benchmark_json_quote(self.name) +
  ",\"category\":" +
  benchmark_json_quote(self.category) +
  ",\"passed\":" +
  self.passed.to_string() +
  ",\"output_chars\":" +
  self.output_chars.to_string() +
  ",\"expected_chars\":" +
  self.expected_chars.to_string() +
  ",\"nodes_visited\":" +
  self.nodes_visited.to_string() +
  ",\"iterations\":" +
  self.iterations.to_string() +
  ",\"unicode_chars\":" +
  self.unicode_chars.to_string() +
  ",\"missing_variables\":" +
  self.missing_variables.to_string() +
  "}"
}

///|
pub fn benchmark_all_passed(results : Array[BenchmarkResult]) -> Bool {
  for result in results {
    if !result.passed() {
      return false
    }
  }
  true
}

///|
pub fn benchmark_total_output_chars(results : Array[BenchmarkResult]) -> Int {
  let mut total = 0
  for result in results {
    total += result.output_chars()
  }
  total
}

///|
pub fn benchmark_total_iterations(results : Array[BenchmarkResult]) -> Int {
  let mut total = 0
  for result in results {
    total += result.iterations()
  }
  total
}

///|
/// Serialize the complete suite without timestamps or machine-specific data.
pub fn benchmark_report_json(results : Array[BenchmarkResult]) -> String {
  let mut output = "["
  let mut first = true
  for result in results {
    if !first {
      output += ","
    }
    first = false
    output += result.to_json()
  }
  output + "]"
}

///|
fn benchmark_json_quote(value : String) -> String {
  "\"" + escape_benchmark_json(value) + "\""
}

///|
fn escape_benchmark_json(value : String) -> String {
  let mut output = ""
  for c in value {
    output += match c {
      '"' => "\\\""
      '\\' => "\\\\"
      '\n' => "\\n"
      '\r' => "\\r"
      '\t' => "\\t"
      _ => c.to_string()
    }
  }
  output
}

///|
fn count_unicode(value : String) -> Int {
  let mut count = 0
  for c in value {
    if c.to_int() > 127 {
      count += 1
    }
  }
  count
}

///|
fn failure_text(failure : RenderFailure) -> String {
  match failure {
    OutputLimitExceeded(limit, actual) =>
      "output limit " + limit.to_string() + " at " + actual.to_string()
    IterationLimitExceeded(limit) => "iteration limit " + limit.to_string()
    DepthLimitExceeded(limit) => "depth limit " + limit.to_string()
  }
}
