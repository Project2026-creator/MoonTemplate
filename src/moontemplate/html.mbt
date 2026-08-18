///|
/// Safe, composable HTML fragments for the most common template output path.
pub struct HtmlBuilder {
  parts : Array[String]
}

///|
pub fn HtmlBuilder::new() -> HtmlBuilder {
  { parts: [] }
}

///|
pub fn HtmlBuilder::raw(self : HtmlBuilder, value : String) -> HtmlBuilder {
  self.parts.push(value)
  self
}

///|
pub fn HtmlBuilder::text(self : HtmlBuilder, value : String) -> HtmlBuilder {
  self.raw(escape_html(value))
}

///|
pub fn HtmlBuilder::open(self : HtmlBuilder, tag : String) -> HtmlBuilder {
  self.raw("<" + safe_filename(tag) + ">")
}

///|
pub fn HtmlBuilder::close(self : HtmlBuilder, tag : String) -> HtmlBuilder {
  self.raw("</" + safe_filename(tag) + ">")
}

///|
pub fn HtmlBuilder::element(
  self : HtmlBuilder,
  tag : String,
  value : String,
) -> HtmlBuilder {
  self.open(tag).text(value).close(tag)
}

///|
pub fn HtmlBuilder::attribute(
  self : HtmlBuilder,
  key : String,
  value : String,
) -> HtmlBuilder {
  let safe_key = safe_filename(key)
  self.raw(" " + safe_key + "=\"" + escape_html(value) + "\"")
}

///|
pub fn HtmlBuilder::open_with_attributes(
  self : HtmlBuilder,
  tag : String,
  attributes : Array[(String, String)],
) -> HtmlBuilder {
  let _ = self.raw("<" + safe_filename(tag))
  for pair in attributes {
    let (key, value) = pair
    let _ = self.attribute(key, value)
  }
  self.raw(">")
}

///|
pub fn HtmlBuilder::join(self : HtmlBuilder, separator : String) -> HtmlBuilder {
  let snapshot = self.parts.copy()
  self.parts.clear()
  for index, part in snapshot {
    if index > 0 {
      self.parts.push(separator)
    }
    self.parts.push(part)
  }
  self
}

///|
pub fn HtmlBuilder::render(self : HtmlBuilder) -> String {
  self.parts.join("")
}

///|
pub fn html_escape_attribute(value : String) -> String {
  escape_html(value)
}

///|
pub fn html_document(title : String, body : String) -> String {
  HtmlBuilder::new()
  .raw("<!doctype html><html><head><meta charset=\"utf-8\">")
  .element("title", title)
  .raw("</head><body>")
  .raw(body)
  .raw("</body></html>")
  .render()
}

///|
pub fn html_list(items : Array[String]) -> String {
  let builder = HtmlBuilder::new().open("ul")
  for item in items {
    let _ = builder.element("li", item)
  }
  builder.close("ul").render()
}

///|
pub fn html_attributes(values : Context) -> String {
  let result = StringBuilder::new()
  for pair in context_to_sorted_pairs(values) {
    let (key, value) = pair
    result.write_char(' ')
    result.write_string(safe_filename(key))
    result.write_string("=\"")
    result.write_string(escape_html(value))
    result.write_char('"')
  }
  result.to_string()
}

///|
pub fn html_tag(tag : String, attributes : Context, body : String) -> String {
  "<" +
  safe_filename(tag) +
  html_attributes(attributes) +
  ">" +
  body +
  "</" +
  safe_filename(tag) +
  ">"
}

///|
pub fn html_comment(value : String) -> String {
  "<!--" + value.replace_all(old="--", new="-") + "-->"
}

///|
pub fn html_script_json(context : Context) -> String {
  "<script type=\"application/json\">" + json_object(context) + "</script>"
}

///|
pub fn html_meta(name : String, content : String) -> String {
  "<meta name=\"" +
  escape_html(name) +
  "\" content=\"" +
  escape_html(content) +
  "\">"
}
