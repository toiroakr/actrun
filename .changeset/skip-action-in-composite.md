---
"@toiroakr/actrun": patch
---

`--skip-action` (and `local_skip_actions`) now also skips a matching action used inside a local composite action or a reusable workflow, not only a step of the workflow itself. Such an action is no longer listed in the third-party actions confirmation, fetched, or run, and a local action that matches is not looked into. Each skipped step is shown as a `skip  <job>/<step> / <inner step> (<uses>)` line, like a skipped step of the workflow, once per job of a matrix. Before, a workflow whose composite action used a skipped action still stopped at the `Continue? [y/N]` prompt, and fetched and ran the action once confirmed.
