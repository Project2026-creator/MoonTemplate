///|
/// Application-facing metrics for comparing rendering workloads without
/// relying on wall-clock timing or host-specific counters.
pub struct RenderSummary {
  mut documents : Int
  mut successful : Int
  mut failed : Int
  mut output_chars : Int
  mut missing_variables : Int
  mut iterations : Int
} derive(Debug, Eq)

///|
pub fn RenderSummary::new() -> RenderSummary {
  {
    documents: 0,
    successful: 0,
    failed: 0,
    output_chars: 0,
    missing_variables: 0,
    iterations: 0,
  }
}

///|
pub fn RenderSummary::record_success(
  self : RenderSummary,
  report : RenderReport,
) -> RenderSummary {
  self.documents += 1
  self.successful += 1
  let metrics = report.metrics()
  self.output_chars += metrics.output_chars()
  self.missing_variables += metrics.missing_variables()
  self.iterations += metrics.iterations()
  self
}

///|
pub fn RenderSummary::record_failure(self : RenderSummary) -> RenderSummary {
  self.documents += 1
  self.failed += 1
  self
}

///|
pub fn RenderSummary::documents(self : RenderSummary) -> Int {
  self.documents
}

///|
pub fn RenderSummary::successful(self : RenderSummary) -> Int {
  self.successful
}

///|
pub fn RenderSummary::failed(self : RenderSummary) -> Int {
  self.failed
}

///|
pub fn RenderSummary::output_chars(self : RenderSummary) -> Int {
  self.output_chars
}

///|
pub fn RenderSummary::missing_variables(self : RenderSummary) -> Int {
  self.missing_variables
}

///|
pub fn RenderSummary::iterations(self : RenderSummary) -> Int {
  self.iterations
}

///|
pub fn RenderSummary::success_rate(self : RenderSummary) -> String {
  if self.documents == 0 {
    "0%"
  } else {
    "\{self.successful * 100 / self.documents}%"
  }
}

///|
pub fn RenderSummary::to_context(self : RenderSummary) -> Context {
  Context::new()
  .set_int("documents", self.documents)
  .set_int("successful", self.successful)
  .set_int("failed", self.failed)
  .set_int("output_chars", self.output_chars)
  .set_int("missing_variables", self.missing_variables)
  .set_int("iterations", self.iterations)
  .set("success_rate", self.success_rate())
}

///|
pub fn summary_json(summary : RenderSummary) -> String {
  json_object(summary.to_context())
}

///|
pub fn summarize_reports(
  reports : Array[Result[RenderReport, RenderFailure]],
) -> RenderSummary {
  let summary = RenderSummary::new()
  for report in reports {
    match report {
      Ok(value) => {
        let _ = summary.record_success(value)
      }
      Err(_) => {
        let _ = summary.record_failure()
      }
    }
  }
  summary
}

///|
pub fn compare_summaries(
  left : RenderSummary,
  right : RenderSummary,
) -> Array[(String, Int)] {
  [
    ("documents", left.documents() - right.documents()),
    ("successful", left.successful() - right.successful()),
    ("failed", left.failed() - right.failed()),
    ("output_chars", left.output_chars() - right.output_chars()),
    ("missing_variables", left.missing_variables() - right.missing_variables()),
    ("iterations", left.iterations() - right.iterations()),
  ]
}
