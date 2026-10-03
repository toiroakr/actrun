///|
test "logical expressions return the selected operand for interpolation" {
  let ctx = new_if_condition_context(github_context={ "event.number": "42" })
  assert_eq(
    evaluate_string_function_expression("'' || github.event.number", ctx),
    Some("42"),
  )
  assert_eq(
    evaluate_string_function_expression("'' || github.event.missing", ctx),
    Some(""),
  )
  assert_eq(
    evaluate_string_function_expression("true && 'selected' || 'fallback'", ctx),
    Some("selected"),
  )
  assert_eq(
    evaluate_string_function_expression(
      "'yes' && 'selected' || 'fallback'", ctx,
    ),
    Some("selected"),
  )
}

///|
test "logical operands evaluate comparisons negation and numeric truthiness" {
  let ctx = new_if_condition_context(env_context={ "MODE": "release" })
  for
    (expression, expected) in [
      ("env.MODE == 'release' && 'yes' || 'no'", "yes"),
      ("env.MODE != 'release' && 'yes' || 'no'", "no"),
      ("!false && 'yes' || 'no'", "yes"),
      ("0 || 'fallback'", "fallback"),
      ("(false) && 'yes' || 'no'", "no"),
    ] {
    assert_eq(
      evaluate_string_function_expression(expression, ctx),
      Some(expected),
    )
  }
}

///|
test "substituted composite input quotes survive expression evaluation" {
  let expression = substitute_inputs_text("${{ format('{0}', inputs.text) }}", {
    "text": "it's fine",
  })
  assert_eq(
    evaluate_string_function_expression(
      unwrap_if_expression(expression),
      new_if_condition_context(),
    ),
    Some("it's fine"),
  )
}
