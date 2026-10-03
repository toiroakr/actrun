---
"@toiroakr/actrun": patch
---

Honor composite action call conditions once before executing their children. Skip nested descendants, including always steps, when a call condition is false, and preserve the skipped call outcome.
