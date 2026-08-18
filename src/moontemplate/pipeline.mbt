///|
/// A render pipeline composes predictable post-processing stages around an
/// Engine. Stages are plain functions, so applications can add formatting,
/// signing, or transport-specific transforms without changing the parser.
pub struct RenderPipeline {
  stages : Array[PipelineStage]
}

///|
type PipelineStage = (String, (String) -> String)

///|
pub fn RenderPipeline::new() -> RenderPipeline {
  { stages: [] }
}

///|
pub fn RenderPipeline::add(
  self : RenderPipeline,
  name : String,
  stage : (String) -> String,
) -> RenderPipeline {
  if name.trim() != "" {
    self.stages.push((name.trim().to_owned(), stage))
  }
  self
}

///|
pub fn RenderPipeline::length(self : RenderPipeline) -> Int {
  self.stages.length()
}

///|
pub fn RenderPipeline::names(self : RenderPipeline) -> Array[String] {
  let result = []
  for item in self.stages {
    let (name, _) = item
    result.push(name)
  }
  result
}

///|
pub fn RenderPipeline::apply(self : RenderPipeline, value : String) -> String {
  let mut result = value
  for item in self.stages {
    let (_, stage) = item
    result = stage(result)
  }
  result
}

///|
pub fn RenderPipeline::apply_to(
  self : RenderPipeline,
  engine : Engine,
  context : Context,
) -> String {
  self.apply(engine.render(context.to_map()))
}

///|
pub fn RenderPipeline::remove(self : RenderPipeline, name : String) -> Bool {
  for index in 0..<self.stages.length() {
    let (stage_name, _) = self.stages[index]
    if stage_name == name {
      let _ = self.stages.remove(index)
      return true
    }
  }
  false
}

///|
pub fn pipeline_trim() -> (String) -> String {
  fn(value) { value.trim().to_owned() }
}

///|
pub fn pipeline_collapse_spaces() -> (String) -> String {
  fn(value) {
    let mut result = ""
    let mut previous_space = false
    for c in value {
      let space = c == ' ' || c == '\t' || c == '\n'
      if space {
        if !previous_space {
          result += " "
        }
      } else {
        result += c.to_string()
      }
      previous_space = space
    }
    result
  }
}

///|
pub fn pipeline_ensure_trailing_newline() -> (String) -> String {
  fn(value) { if value.has_suffix("\n") { value } else { value + "\n" } }
}

///|
pub fn pipeline_prefix(prefix : String) -> (String) -> String {
  fn(value) { text_indent(value, prefix) }
}

///|
pub fn pipeline_suffix(suffix : String) -> (String) -> String {
  fn(value) { value + suffix }
}

///|
pub fn pipeline_limit(max_chars : Int) -> (String) -> String {
  fn(value) {
    if max_chars <= 0 {
      ""
    } else if value.char_length() <= max_chars {
      value
    } else {
      value[:max_chars].to_owned()
    }
  }
}

///|
pub fn render_through(
  engine : Engine,
  context : Context,
  pipeline : RenderPipeline,
) -> String {
  pipeline.apply_to(engine, context)
}
