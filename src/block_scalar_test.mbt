///|
fn block_scalar_job(yaml : String, id : String) -> JobSpec raise {
  let parsed = parse_workflow_yaml(yaml)
  guard parsed.workflow is Some(workflow) else {
    fail(parsed.errors.join("\n"))
  }
  for job in workflow.jobs {
    if job.id == id {
      return job
    }
  }
  fail("missing job: " + id)
}

///|
test "a strip-chomped job if keeps the keys that follow it" {
  let job = block_scalar_job(
    (
      #|on: push
      #|jobs:
      #|  a:
      #|    runs-on: ubuntu-latest
      #|    steps:
      #|      - run: echo a
      #|  b:
      #|    needs: a
      #|    if: |-
      #|      always() && (
      #|        needs.a.result == 'success'
      #|      )
      #|    runs-on: ubuntu-latest
      #|    steps:
      #|      - run: echo b
    ),
    "b",
  )
  assert_eq(job.if_condition, "always() && (\n  needs.a.result == 'success'\n)")
  assert_eq(job.runs_on, ["ubuntu-latest"])
  assert_eq(job.steps.length(), 1)
}

///|
test "a strip-chomped folded job if keeps the keys that follow it" {
  let job = block_scalar_job(
    (
      #|on: push
      #|jobs:
      #|  b:
      #|    if: >-
      #|      always()
      #|    runs-on: ubuntu-latest
      #|    steps:
      #|      - run: echo b
    ),
    "b",
  )
  assert_eq(job.if_condition, "always()")
  assert_eq(job.steps.length(), 1)
}

///|
test "a strip-chomped env value keeps the keys that follow it" {
  let job = block_scalar_job(
    (
      #|on: push
      #|jobs:
      #|  b:
      #|    env:
      #|      X: |-
      #|        hello
      #|    runs-on: ubuntu-latest
      #|    steps:
      #|      - run: echo b
    ),
    "b",
  )
  assert_eq(job.env.get("X"), Some("hello"))
  assert_eq(job.steps.length(), 1)
}

///|
test "a strip-chomped step if is read as its body, not as the header" {
  let job = block_scalar_job(
    (
      #|on: push
      #|jobs:
      #|  b:
      #|    runs-on: ubuntu-latest
      #|    steps:
      #|      - if: |-
      #|          always()
      #|        run: echo b
      #|      - run: echo c
    ),
    "b",
  )
  assert_eq(job.steps[0].if_condition, "always()")
  assert_eq(job.steps[0].run, Some("echo b"))
  assert_eq(job.steps.length(), 2)
}

///|
test "a strip-chomped if as the last key of a job is read as its body" {
  let job = block_scalar_job(
    (
      #|on: push
      #|jobs:
      #|  b:
      #|    runs-on: ubuntu-latest
      #|    steps:
      #|      - run: echo b
      #|    if: |-
      #|      always()
    ),
    "b",
  )
  assert_eq(job.if_condition, "always()")
}

///|
fn block_scalar_step_run(body : String) -> String? raise {
  let job = block_scalar_job(
    "on: push\njobs:\n  b:\n    runs-on: ubuntu-latest\n    steps:\n" +
    body +
    "      - run: echo next\n",
    "b",
  )
  job.steps[0].run
}

///|
test "a clip-chomped literal ends with exactly one line break" {
  assert_eq(
    block_scalar_step_run(
      (
        #|      - run: |
        #|          echo a
        #|          echo b
        #|
        #|
        #|
      ),
    ),
    Some("echo a\necho b\n"),
  )
}

///|
test "a keep-chomped literal keeps the trailing empty lines" {
  assert_eq(
    block_scalar_step_run(
      (
        #|      - run: |+
        #|          echo a
        #|
        #|
      ),
    ),
    Some("echo a\n\n"),
  )
}

///|
test "a folded scalar joins lines with spaces and turns empty lines into line breaks" {
  assert_eq(
    block_scalar_step_run(
      (
        #|      - run: >-
        #|          echo a
        #|          b
        #|
        #|          echo c
        #|
      ),
    ),
    Some("echo a b\necho c"),
  )
}

///|
test "a folded scalar keeps the line breaks around more-indented lines" {
  assert_eq(
    block_scalar_step_run(
      (
        #|      - run: >-
        #|          a
        #|            b
        #|          c
        #|
      ),
    ),
    Some("a\n  b\nc"),
  )
}

///|
test "an indentation indicator keeps the leading spaces of the first line" {
  assert_eq(
    block_scalar_step_run(
      (
        #|      - run: |2-
        #|            indented
        #|          base
        #|
      ),
    ),
    Some("  indented\nbase"),
  )
}

///|
test "a block scalar header may be followed by a comment" {
  assert_eq(
    block_scalar_step_run(
      (
        #|      - run: |- # note
        #|          echo a
        #|
      ),
    ),
    Some("echo a"),
  )
}

///|
test "a keep-chomped scalar with only empty lines keeps one line break per empty line" {
  let job = block_scalar_job(
    (
      #|on: push
      #|jobs:
      #|  b:
      #|    env:
      #|      ONE: |+
      #|
      #|      TWO: >+
      #|
      #|
      #|      NONE: |-
      #|
      #|    runs-on: ubuntu-latest
      #|    steps:
      #|      - run: echo b
    ),
    "b",
  )
  assert_eq(job.env.get("ONE"), Some("\n"))
  assert_eq(job.env.get("TWO"), Some("\n\n"))
  assert_eq(job.env.get("NONE"), Some(""))
}

///|
test "lines starting with # inside a block scalar are content, not comments" {
  assert_eq(
    block_scalar_step_run(
      (
        #|      - run: |
        #|          # install
        #|          cat <<EOF > out.md
        #|          # Title
        #|          EOF
        #|
      ),
    ),
    Some("# install\ncat <<EOF > out.md\n# Title\nEOF\n"),
  )
}

///|
test "a comment line indented less than the content ends the block scalar" {
  let job = block_scalar_job(
    (
      #|on: push
      #|jobs:
      #|  b:
      #|    env:
      #|      X: |
      #|        hello
      #|    # a comment
      #|    runs-on: ubuntu-latest
      #|    steps:
      #|      - run: echo b
    ),
    "b",
  )
  assert_eq(job.env.get("X"), Some("hello\n"))
  assert_eq(job.steps.length(), 1)
}
