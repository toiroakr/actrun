---
"@toiroakr/actrun": patch
---

Read YAML block scalars with chomping and indentation indicators (`|-`, `>-`, `|+`, `|2-`, ...) in workflows. A key such as `if: |-` no longer drops the keys that follow it (`jobs.<id>.steps is required`) or reads `|-` itself as its value. Block scalar values now end with the line breaks their chomping indicator asks for, so a plain `run: |` script ends with one line break as on GitHub Actions, and folded scalars (`>`) fold lines as YAML specifies.
