---
"@toiroakr/actrun": patch
---

`--dry-run` now fetches remote GitHub actions into the action cache before planning, as a real run already does, so a remote composite action (for example `owner/repo/subpath@ref`) is expanded in the plan instead of being reported as `not supported in MVP`. A failed fetch, for example when offline, stays a warning and the plan is still printed. A dry run runs no step; it only clones the referenced action repositories.
