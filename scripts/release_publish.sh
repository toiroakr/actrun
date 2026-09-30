#!/usr/bin/env bash
set -euo pipefail

# Usage: bash scripts/release_publish.sh
# Publishes the version in package.json to npm under the latest dist-tag and
# creates its git tag. When that version is already on npm it only creates a
# missing git tag, so it is safe to run on every push to main.

name="$(node -p "require('./package.json').name")"
version="$(node -p "require('./package.json').version")"

if npm view "$name@$version" version > /dev/null 2>&1; then
  echo "$name@$version is already published"
else
  npm run build
  npm run test:smoke
  # Every fork version is a prerelease such as 0.32.0-fork.1, which npm would
  # not make latest on its own.
  npm publish --tag latest --access public --ignore-scripts
fi
pnpm exec changeset git-tag
