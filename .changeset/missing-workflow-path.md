---
"@toiroakr/actrun": patch
---

`actrun <arg>` now reports `unknown command: <arg>` with the usage when `<arg>` is not a `.yml` / `.yaml` path, instead of trying to run it as a workflow file. A workflow file that does not exist now fails with `workflow file not found: <path>` before any workspace is created, and a workflow file missing from the worktree/tmp workspace (for example, not committed yet) fails with a hint to commit it or pass `--include-dirty` / `--local`. A workspace is now removed even when the run stops early with an error.
