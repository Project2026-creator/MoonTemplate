///|
/// Batch rendering keeps the input order stable and reports per-item errors
/// without discarding successful results.
pub struct BatchItem {
  name : String
  source : String
  context : Context
} derive(Debug, Eq)

///|
pub struct BatchResult {
  name : String
  output : String
  error : String?
} derive(Debug, Eq)

///|
pub fn BatchItem::new(
  name : String,
  source : String,
  context : Context,
) -> BatchItem {
  { name, source, context }
}

///|
pub fn BatchItem::name(self : BatchItem) -> String {
  self.name
}

///|
pub fn BatchItem::source(self : BatchItem) -> String {
  self.source
}

///|
pub fn BatchResult::name(self : BatchResult) -> String {
  self.name
}

///|
pub fn BatchResult::output(self : BatchResult) -> String {
  self.output
}

///|
pub fn BatchResult::error(self : BatchResult) -> String? {
  self.error
}

///|
pub fn BatchResult::is_ok(self : BatchResult) -> Bool {
  self.error is None
}

///|
pub fn render_batch(items : Array[BatchItem]) -> Array[BatchResult] {
  let results = []
  for item in items {
    match Engine::new(item.source) {
      Ok(engine) =>
        results.push({
          name: item.name,
          output: engine.render(item.context.to_map()),
          error: None,
        })
      Err(error) =>
        results.push({ name: item.name, output: "", error: Some(error) })
    }
  }
  results
}

///|
pub fn batch_successes(results : Array[BatchResult]) -> Array[BatchResult] {
  let output = []
  for result in results {
    if result.is_ok() {
      output.push(result)
    }
  }
  output
}

///|
pub fn batch_failures(results : Array[BatchResult]) -> Array[BatchResult] {
  let output = []
  for result in results {
    if !result.is_ok() {
      output.push(result)
    }
  }
  output
}

///|
pub fn batch_outputs(results : Array[BatchResult]) -> Array[(String, String)] {
  let output = []
  for result in results {
    if result.is_ok() {
      output.push((result.name, result.output))
    }
  }
  output
}

///|
pub fn batch_error_report(results : Array[BatchResult]) -> String {
  let result = StringBuilder::new()
  for item in results {
    match item.error {
      Some(error) => {
        result.write_string(item.name)
        result.write_string(": ")
        result.write_string(error)
        result.write_char('\n')
      }
      None => ()
    }
  }
  result.to_string()
}

///|
pub fn batch_render_with_pipeline(
  items : Array[BatchItem],
  pipeline : RenderPipeline,
) -> Array[BatchResult] {
  let results = []
  for item in items {
    match Engine::new(item.source) {
      Ok(engine) =>
        results.push({
          name: item.name,
          output: pipeline.apply_to(engine, item.context),
          error: None,
        })
      Err(error) =>
        results.push({ name: item.name, output: "", error: Some(error) })
    }
  }
  results
}

///|
pub fn batch_validate(
  items : Array[BatchItem],
) -> Array[(String, Array[Diagnostic])] {
  let output = []
  for item in items {
    match Engine::new_with_diagnostics(item.source) {
      Ok(_) => ()
      Err(errors) => output.push((item.name, errors))
    }
  }
  output
}
