///|
test "syntax diagnostics report Unicode-aware line and column" {
  let result = Engine::new_with_diagnostics("标题\n{{ missing")
  match result {
    Err(diagnostics) => {
      let diagnostic = diagnostics[0]
      assert_true(diagnostic.kind() == Syntax)
      assert_eq(diagnostic.line(), 2)
      assert_eq(diagnostic.column(), 1)
      assert_eq(diagnostic.source_line(), "{{ missing")
      assert_eq(diagnostic.code(), "TMPL_PARSE")
    }
    Ok(_) => fail("Expected an unterminated variable diagnostic")
  }
}

///|
test "lexical diagnostics report an unterminated comment" {
  match Engine::new_with_diagnostics("before\n{# not closed") {
    Err(diagnostics) => {
      let diagnostic = diagnostics[0]
      assert_true(diagnostic.kind() == Lexical)
      assert_eq(diagnostic.line(), 2)
      assert_eq(diagnostic.source_line(), "{# not closed")
      assert_eq(diagnostic.code(), "TMPL_LEX")
    }
    Ok(_) => fail("Expected an unterminated comment diagnostic")
  }
}

///|
test "filter diagnostics reject invalid parameter types" {
  match Engine::new_with_diagnostics("{{ name | truncate(\"five\") }}") {
    Err(diagnostics) => {
      let diagnostic = diagnostics[0]
      assert_true(diagnostic.kind() == Filter)
      assert_true(diagnostic.message().contains("truncate"))
      assert_eq(diagnostic.code(), "TMPL_FILTER")
    }
    Ok(_) => fail("Expected a filter argument diagnostic")
  }
}

///|
test "strict render diagnoses unknown legacy filters" {
  let engine = Engine::new("{{ name | missing }}").unwrap()
  let context : Map[String, String] = Map([])
  context.set("name", "MoonBit")
  match engine.render_strict(context) {
    Err(diagnostics) => {
      let diagnostic = diagnostics[0]
      assert_true(diagnostic.kind() == Filter)
      assert_eq(diagnostic.line(), 0)
      assert_eq(diagnostic.column(), 0)
    }
    Ok(_) => fail("Expected strict rendering to reject an unknown filter")
  }
}
