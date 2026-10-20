///|
test "parser text and variable" {
  let tokens = [
    @moontemplate.Token::Text("hello "),
    @moontemplate.Token::VarStart,
    @moontemplate.Token::Identifier("name"),
    @moontemplate.Token::VarEnd,
  ]
  let parser = @moontemplate.Parser::new(tokens)
  let nodes = parser.parse().unwrap()
  assert_eq(nodes.length(), 2)
  assert_true(nodes[0] == @moontemplate.Node::Text("hello "))
  assert_true(nodes[1] == @moontemplate.Node::Variable("name", []))
}

///|
test "parser variable filters and else branch" {
  let tokens = @moontemplate.Lexer::new(
    "{{ name | trim | uppercase }}{% if show %}yes{% else %}no{% endif %}",
  ).tokenize()
  let parser = @moontemplate.Parser::new(tokens)
  let nodes = parser.parse().unwrap()
  assert_true(
    nodes ==
    [
      @moontemplate.Node::Variable("name", ["trim", "uppercase"]),
      @moontemplate.Node::If("show", [@moontemplate.Node::Text("yes")], [
        @moontemplate.Node::Text("no"),
      ]),
    ],
  )
}

///|
test "parser reports missing endif" {
  let tokens = @moontemplate.Lexer::new("{% if show %}yes").tokenize()
  let parser = @moontemplate.Parser::new(tokens)
  match parser.parse() {
    Err(message) => assert_eq(message, "Expected {% endif %}")
    Ok(_) => fail("Expected parser error for missing endif")
  }
}

///|
test "parser reports missing endfor" {
  let tokens = @moontemplate.Lexer::new("{% for item in list %}{{ item }}").tokenize()
  let parser = @moontemplate.Parser::new(tokens)
  match parser.parse() {
    Err(message) => assert_eq(message, "Expected {% endfor %}")
    Ok(_) => fail("Expected parser error for missing endfor")
  }
}

///|
test "parser rejects filter without a name" {
  let tokens = @moontemplate.Lexer::new("{{ name | }}").tokenize()
  let parser = @moontemplate.Parser::new(tokens)
  match parser.parse() {
    Err(message) => assert_eq(message, "Expected filter name after |")
    Ok(_) => fail("Expected parser error for missing filter name")
  }
}
