#!/usr/bin/env bash
set -euo pipefail

# Usage: bash scripts/release_publish.sh
# Tags the current commit as v<version>, publishes that version to npm under
# the latest dist-tag, and creates its GitHub Release from the matching
# CHANGELOG.md section. Each step is skipped when it is already done, so it is
# safe to run on every push to main and it completes a partially failed run.

name="$(node -p "require('./package.json').name")"
version="$(node -p "require('./package.json').version")"
tag="v$version"

notes="$(awk -v heading="## $version" '
  $0 == heading { found = 1; next }
  found && /^## / { exit }
  found { print }
' CHANGELOG.md | sed -e '/./,$!d')"
if [ -z "$notes" ]; then
  echo "CHANGELOG.md has no '## $version' section" >&2
  exit 1
fi

# Tag before publishing so a retry on a later push still points the tag at
# the commit that produced the package.
if git ls-remote --exit-code --tags origin "refs/tags/$tag" > /dev/null; then
  echo "Tag $tag already exists"
else
  git tag "$tag" HEAD
  git push origin "refs/tags/$tag"
fi

if npm view "$name@$version" version > /dev/null 2>&1; then
  echo "$name@$version is already published"
else
  npm run build
  npm run test:smoke
  # Every fork version is a prerelease such as 0.32.0-fork.1, which npm would
  # not make latest on its own.
  npm publish --tag latest --access public --ignore-scripts
fi

if gh release view "$tag" > /dev/null 2>&1; then
  echo "GitHub Release $tag already exists"
else
  gh release create "$tag" --verify-tag --title "$tag" --notes "$notes"
fi
