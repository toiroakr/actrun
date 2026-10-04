---
"@toiroakr/actrun": patch
---

Honor composite action call conditions once before executing their children. Skip nested descendants, including always steps, when a call condition is false, and preserve the skipped call outcome.

Retain call conditions and outcomes when all child actions are excluded with `--skip-action`.

Evaluate call conditions with the composite call's GitHub context and omit unreachable `continue-on-error` coverage for skipped calls.
