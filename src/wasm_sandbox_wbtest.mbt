///|
fn wasm_sandbox_has_string(values : Array[String], expected : String) -> Bool {
  let mut found = false
  for value in values {
    if value == expected {
      found = true
    }
  }
  found
}

///|
test "resolve_wasm_runner_command: nodejs uses wasi shim" {
  let (cmd, args) = resolve_wasm_runner_command(
    "nodejs",
    ["run", "module.wasm"],
    "",
  )
  @debug.debug_inspect(
    cmd,
    content=(
      #|"nodejs"
    ),
  )
  @debug.assert_eq(args[0].contains("wasi-runner.mjs"), true)
  @debug.debug_inspect(
    args[1],
    content=(
      #|"run"
    ),
  )
  @debug.debug_inspect(
    args[2],
    content=(
      #|"module.wasm"
    ),
  )
}

///|
test "resolve_wasm_runner_command: node.exe uses wasi shim" {
  let (cmd, args) = resolve_wasm_runner_command_with_kind(
    "",
    "/tmp/tools/node.exe",
    ["run", "module.wasm"],
    "",
  )
  @debug.debug_inspect(
    cmd,
    content=(
      #|"/tmp/tools/node.exe"
    ),
  )
  @debug.assert_eq(args[0].contains("wasi-runner.mjs"), true)
  @debug.debug_inspect(
    args[1],
    content=(
      #|"run"
    ),
  )
  @debug.debug_inspect(
    args[2],
    content=(
      #|"module.wasm"
    ),
  )
}

///|
test "resolve_wasm_runner_command: explicit deno uses deno shim flags" {
  let (cmd, args) = resolve_wasm_runner_command_with_kind(
    "deno",
    "/tmp/tools/custom-wasm-runner",
    ["run", "module.wasm"],
    "",
  )
  @debug.debug_inspect(
    cmd,
    content=(
      #|"/tmp/tools/custom-wasm-runner"
    ),
  )
  @debug.debug_inspect(
    args[0],
    content=(
      #|"run"
    ),
  )
  @debug.debug_inspect(
    args[1],
    content=(
      #|"--allow-all"
    ),
  )
  @debug.assert_eq(args[2].contains("wasi-runner.mjs"), true)
  @debug.debug_inspect(
    args[3],
    content=(
      #|"run"
    ),
  )
  @debug.debug_inspect(
    args[4],
    content=(
      #|"module.wasm"
    ),
  )
}

///|
test "resolve_wasm_runner_command: explicit v8 uses js shim without deno flags" {
  let (cmd, args) = resolve_wasm_runner_command_with_kind(
    "v8",
    "/tmp/tools/custom-wasm-runner",
    ["run", "module.wasm"],
    "",
  )
  @debug.debug_inspect(
    cmd,
    content=(
      #|"/tmp/tools/custom-wasm-runner"
    ),
  )
  @debug.assert_eq(args[0].contains("wasi-runner.mjs"), true)
  @debug.debug_inspect(
    args[1],
    content=(
      #|"run"
    ),
  )
  @debug.debug_inspect(
    args[2],
    content=(
      #|"module.wasm"
    ),
  )
}

///|
test "wasi_runner_shim_candidates: includes install path patterns" {
  let candidates = wasi_runner_shim_candidates("/tmp/actrun-workspace")
  @debug.assert_eq(
    wasm_sandbox_has_string(candidates, "/usr/local/lib/actrun/wasi-runner.mjs"),
    true,
  )
  @debug.assert_eq(
    wasm_sandbox_has_string(
      candidates, "/tmp/actrun-workspace/node_modules/@mizchi/actrun/scripts/wasi-runner.mjs",
    ),
    true,
  )
}

///|
test "wasi_runner_shim_candidates: includes the shim shipped in the @toiroakr/actrun npm package" {
  let candidates = wasi_runner_shim_candidates("/tmp/actrun-workspace")
  @debug.assert_eq(
    wasm_sandbox_has_string(
      candidates, "node_modules/@toiroakr/actrun/scripts/wasi-runner.mjs",
    ),
    true,
  )
  @debug.assert_eq(
    wasm_sandbox_has_string(
      candidates, "/tmp/actrun-workspace/node_modules/@toiroakr/actrun/scripts/wasi-runner.mjs",
    ),
    true,
  )
}

///|
test "wasi_runner_shim_candidates: an explicitly configured shim path is tried first" {
  let candidates = wasi_runner_shim_candidates(
    "/tmp/actrun-workspace",
    configured="/opt/npm/lib/node_modules/@toiroakr/actrun/scripts/wasi-runner.mjs",
  )
  @debug.assert_eq(
    candidates[0],
    "/opt/npm/lib/node_modules/@toiroakr/actrun/scripts/wasi-runner.mjs",
  )
}
