#!/usr/bin/env bash
set -euo pipefail

# Usage: bash scripts/release_publish.sh
# Publishes the version in package.json to npm under the latest dist-tag from
# a commit tagged v<version>, and creates its GitHub Release from the matching
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

tag_commit="$(git ls-remote --tags origin "refs/tags/$tag" | cut -f1)"
if npm view "$name@$version" version > /dev/null 2>&1; then
  echo "$name@$version is already published"
  if [ -z "$tag_commit" ]; then
    # Tagging HEAD here could point the tag at a commit that did not produce
    # the published package.
    echo "$tag is missing: push it from the commit that $name@$version was published from" >&2
    exit 1
  fi
else
  # Point the tag at the commit about to be published, even if a failed
  # earlier run left it on an older commit: nothing was published from it.
  if [ "$tag_commit" != "$(git rev-parse HEAD)" ]; then
    git tag -f "$tag" HEAD
    git push -f origin "refs/tags/$tag"
  fi
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
