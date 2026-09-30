---
description: Check whether an upstream mizchi/actrun release already covers the features this soft fork carries
on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - testdata/fork-features/upstream.txt
  bots:
    - renovate[bot]
permissions:
  contents: read
  pull-requests: read
  copilot-requests: write
engine: copilot
timeout-minutes: 30
network:
  allowed:
    - defaults
    - github
tools:
  github:
    toolsets: [repos, pull_requests]
  bash:
    - "cat *"
    - "ls *"
    - "head *"
    - "grep *"
    - "git log *"
    - "git show *"
    - "git diff *"
safe-outputs:
  add-comment:
    max: 1
    hide-older-comments: true
steps:
  - name: Fetch the upstream release named in upstream.txt
    run: |
      set -euo pipefail
      if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
        git fetch --unshallow --no-tags origin
      fi
      version=$(sed -n 's/^version=//p' testdata/fork-features/upstream.txt)
      git fetch --no-tags https://github.com/mizchi/actrun.git "refs/tags/$version"
      git worktree add "$RUNNER_TEMP/upstream" FETCH_HEAD
      out="$GITHUB_WORKSPACE/_build/upstream-check"
      mkdir -p "$out"
      echo "$version $(git rev-parse FETCH_HEAD)" > "$out/upstream-version.txt"
  - name: Install MoonBit CLI
    uses: ./.github/actions/setup-moonbit
  - name: Build fork and upstream actrun
    run: |
      set -euo pipefail
      out="$GITHUB_WORKSPACE/_build/upstream-check"
      moon update
      moon build src/cmd/actrun --target native
      (cd "$RUNNER_TEMP/upstream" && moon build src/cmd/actrun --target native) \
        > "$out/upstream-build.log" 2>&1 \
        || echo "upstream build failed" > "$out/upstream-build-failed.txt"
  - name: Collect upstream facts
    run: |
      set -uo pipefail
      out="$GITHUB_WORKSPACE/_build/upstream-check"
      bin=_build/native/debug/build/cmd/actrun/actrun.exe
      base=$(git merge-base HEAD FETCH_HEAD)
      git log --no-merges --format='%h %s' "$base..FETCH_HEAD" > "$out/upstream-commits.txt"
      git log --no-merges --format='%h %s' "FETCH_HEAD..HEAD" > "$out/fork-commits.txt"
      git merge-tree --write-tree --name-only HEAD FETCH_HEAD > "$out/merge-tree.txt" 2>&1
      echo "exit=$?" >> "$out/merge-tree.txt"
      FORK_FEATURES_LOG_DIR="$out/fork-logs" \
        bash scripts/fork_features_check.sh "$PWD/$bin" > "$out/fork.tsv"
      if [ -e "$out/upstream-build-failed.txt" ] || ! "$RUNNER_TEMP/upstream/$bin" --help > /dev/null 2>&1; then
        echo "upstream actrun binary is not runnable" > "$out/upstream-build-failed.txt"
      else
        FORK_FEATURES_LOG_DIR="$out/upstream-logs" FORK_FEATURES_TIMEOUT=60 \
          bash scripts/fork_features_check.sh "$RUNNER_TEMP/upstream/$bin" > "$out/upstream.tsv"
      fi
      true
---

# Upstream feature check

This repository is a soft fork of `mizchi/actrun`: it follows upstream
releases and carries a few extra commits. Each fork-only feature has a fixture
under `testdata/fork-features/<id>/` whose `feature.txt` names the feature, the
fork commit that introduced it, and what it guarantees.

This pull request (opened by Renovate) bumps
`testdata/fork-features/upstream.txt` to a new upstream release. The steps
before you already built this fork and that upstream release and ran every
fixture against both. Read the facts they left in `_build/upstream-check/`:

- `upstream-version.txt`: the upstream tag and commit that was checked
- `upstream.tsv` / `fork.tsv`: `<feature id>\t<pass|fail>` per fixture, with
  per-feature logs in `upstream-logs/` and `fork-logs/`
- `upstream-commits.txt`: upstream commits since the release this fork is
  based on
- `fork-commits.txt`: commits only this fork has
- `merge-tree.txt`: `git merge-tree` output; `exit=1` means merging the
  release conflicts, and the listed paths are the conflicting files
- `upstream-build-failed.txt` (only when upstream could not be built or run)
  and `upstream-build.log`: in that case there is no `upstream.tsv`; report
  the build failure with the relevant log lines instead of classifying features

## What to decide

For every feature id, classify it as one of:

1. **Supported upstream**: `upstream.tsv` says `pass`. The fork commit named in
   `feature.txt` can be dropped when this release is merged. Name the upstream
   commit that introduced the support by reading `upstream-commits.txt` and
   `git show` on the likely candidates.
2. **Partially supported**: `upstream.tsv` says `fail`, but an upstream commit
   clearly works on the same behavior (read the diff). Explain what upstream
   covers, what the fixture still catches (quote the failing lines from
   `upstream-logs/<id>.log`), and what the fork commit would need to keep.
3. **Still fork-only**: `upstream.tsv` says `fail` and no upstream commit
   touches the behavior.

If `fork.tsv` has any `fail`, say so first: the fork itself regressed and the
upstream comparison for that feature is not meaningful.

Then summarize `merge-tree.txt`: whether merging the release would conflict,
and for each conflicting file which fork commit (from `fork-commits.txt`)
touches it.

## Output

Add one comment to this pull request, written in Japanese, containing:

- The checked upstream tag and commit from `upstream-version.txt`.
- A table with one row per feature id: classification, upstream commit (if
  any), fork commit, and the evidence you used.
- The merge outlook from `merge-tree.txt`.
- A recommended next step, e.g. which fork commits to drop while merging the
  release, before this pull request is merged.

Explain each point so a reader who has not looked at the code can follow it:
say what the feature does with a concrete example from its `feature.txt` and
fixture, not just its id.

Do not guess. If a log is missing or a build step clearly failed, report that
instead of classifying the feature.
