///|
/// Structured document helpers for the common case where a template engine
/// feeds Markdown, release notes, reports, or generated configuration files.
pub struct Document {
  title : String
  sections : Array[DocumentSection]
  metadata : Context
}

///|
struct DocumentSection {
  heading : String
  level : Int
  body : String
}

///|
pub fn Document::new(title : String) -> Document {
  { title, sections: [], metadata: Context::new() }
}

///|
pub fn Document::set_metadata(
  self : Document,
  key : String,
  value : String,
) -> Document {
  let _ = self.metadata.set(key, value)
  self
}

///|
pub fn Document::add_section(
  self : Document,
  heading : String,
  level : Int,
  body : String,
) -> Document {
  let safe_level = if level < 1 { 1 } else if level > 6 { 6 } else { level }
  self.sections.push({ heading, level: safe_level, body })
  self
}

///|
pub fn Document::section_count(self : Document) -> Int {
  self.sections.length()
}

///|
pub fn Document::title(self : Document) -> String {
  self.title
}

///|
pub fn Document::render_markdown(self : Document) -> String {
  let result = StringBuilder::new()
  if self.title.trim() != "" {
    result.write_string("# ")
    result.write_string(self.title)
    result.write_string("\n\n")
  }
  for section in self.sections {
    result.write_string(text_repeat("#", section.level))
    result.write_char(' ')
    result.write_string(section.heading)
    result.write_string("\n\n")
    result.write_string(section.body)
    result.write_string("\n\n")
  }
  result.to_string().trim_end().to_owned()
}

///|
pub fn Document::render_metadata(self : Document) -> String {
  let result = StringBuilder::new()
  for pair in context_to_sorted_pairs(self.metadata) {
    let (key, value) = pair
    result.write_string(key)
    result.write_string(": ")
    result.write_string(value)
    result.write_char('\n')
  }
  result.to_string().trim_end().to_owned()
}

///|
pub fn markdown_heading(text : String, level : Int) -> String {
  let safe_level = if level < 1 { 1 } else if level > 6 { 6 } else { level }
  text_repeat("#", safe_level) + " " + text + "\n"
}

///|
pub fn markdown_paragraph(text : String) -> String {
  text.trim().to_owned() + "\n\n"
}

///|
pub fn markdown_bullets(items : Array[String]) -> String {
  let result = StringBuilder::new()
  for item in items {
    result.write_string("- ")
    result.write_string(item)
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn markdown_numbered(items : Array[String]) -> String {
  let result = StringBuilder::new()
  for _, item in items {
    result.write_string("{index + 1}. ")
    result.write_string(item)
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn markdown_quote(text : String) -> String {
  text_indent(text, "> ") + "\n"
}

///|
pub fn markdown_code(language : String, code : String) -> String {
  "```\{language}\n" + code + "\n```\n"
}

///|
pub fn markdown_table(
  headers : Array[String],
  rows : Array[Array[String]],
) -> String {
  let result = StringBuilder::new()
  result.write_char('|')
  for header in headers {
    result.write_char(' ')
    result.write_string(header)
    result.write_string(" |")
  }
  result.write_char('\n')
  result.write_char('|')
  for _ in headers {
    result.write_string(" --- |")
  }
  result.write_char('\n')
  for row in rows {
    result.write_char('|')
    for index in 0..<headers.length() {
      result.write_char(' ')
      if index < row.length() {
        result.write_string(row[index])
      }
      result.write_string(" |")
    }
    result.write_char('\n')
  }
  result.to_string()
}

///|
pub fn markdown_link(label : String, url : String) -> String {
  "[" + label + "](" + safe_header(url) + ")"
}

///|
pub fn markdown_toc(document : Document) -> String {
  let result = StringBuilder::new()
  for section in document.sections {
    let anchor = safe_filename(section.heading).to_lower()
    result.write_string(text_repeat("  ", section.level - 1))
    result.write_string("- [")
    result.write_string(section.heading)
    result.write_string("](#")
    result.write_string(anchor)
    result.write_string(")\n")
  }
  result.to_string()
}

///|
pub fn report_from_template(
  title : String,
  engine : Engine,
  context : Context,
) -> Document {
  Document::new(title).add_section(
    "Generated report",
    2,
    engine.render(context.to_map()),
  )
}
