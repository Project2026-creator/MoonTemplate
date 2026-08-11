///|
test "lexer basic text" {
  let lexer = Lexer::new("hello world")
  let tokens = lexer.tokenize()
  assert_true(tokens[0] == Text("hello world"))
  assert_true(tokens[1] == EOF)
}

///|
test "lexer variable" {
  let lexer = Lexer::new("hello {{ name }}!")
  let tokens = lexer.tokenize()
  assert_eq(tokens[0], Text("hello "))
  assert_eq(tokens[1], VarStart)
  assert_eq(tokens[2], Identifier("name"))
  assert_eq(tokens[3], VarEnd)
  assert_eq(tokens[4], Text("!"))
}

///|
test "lexer filter pipeline" {
  let lexer = Lexer::new("{{ name|trim|uppercase }}")
  let tokens = lexer.tokenize()
  assert_true(
    tokens ==
    [
      VarStart,
      Identifier("name"),
      Pipe,
      Identifier("trim"),
      Pipe,
      Identifier("uppercase"),
      VarEnd,
      EOF,
    ],
  )
}
