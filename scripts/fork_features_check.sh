#!/usr/bin/env bash
set -uo pipefail

# Usage: bash scripts/fork_features_check.sh <actrun command...>
# e.g.   bash scripts/fork_features_check.sh _build/native/release/build/cmd/actrun/actrun.exe
#        bash scripts/fork_features_check.sh node /path/to/upstream/dist/actrun.js
# Prints "<feature id>\t<pass|fail>" per fixture under testdata/fork-features
# and exits non-zero when any feature fails.

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <actrun command...>" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FEATURES_DIR="$REPO_ROOT/testdata/fork-features"
TIMEOUT_SECONDS="${FORK_FEATURES_TIMEOUT:-120}"
LOG_DIR="${FORK_FEATURES_LOG_DIR:-$REPO_ROOT/_build/fork-features}"
mkdir -p "$LOG_DIR"

if command -v timeout > /dev/null; then
  with_timeout=(timeout "$TIMEOUT_SECONDS")
elif command -v gtimeout > /dev/null; then
  with_timeout=(gtimeout "$TIMEOUT_SECONDS")
else
  with_timeout=()
fi

failed=0
for dir in "$FEATURES_DIR"/*/; do
  id="$(sed -n 's/^id=//p' "$dir/feature.txt")"
  work="$(mktemp -d)"
  cp -R "$dir/." "$work/"
  (
    cd "$work" &&
      git init -q &&
      git add -A &&
      git -c user.name=fork-features -c user.email=fork-features@localhost \
        -c commit.gpgSign=false commit -qm fixture &&
      ${with_timeout[@]+"${with_timeout[@]}"} "$@" workflow run .github/workflows/check.yml --trust
  ) >"$LOG_DIR/$id.log" 2>&1
  if [ "$?" -eq 0 ]; then
    printf '%s\tpass\n' "$id"
  else
    printf '%s\tfail\n' "$id"
    failed=1
  fi
  rm -rf "$work"
done
exit "$failed"
