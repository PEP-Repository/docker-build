#!/usr/bin/env bash
set -eu -o pipefail

scriptdir="$(realpath "$(dirname -- "$0")")"
cd "$scriptdir"

macos=false
if [ "$(uname)" = Darwin ]; then
  macos=true
fi

git ls-tree -r  --name-only HEAD | while read -r file; do
  if git diff --quiet --exit-code "$file"; then # If unchanged
    if $macos; then
      touch -t "$(git log --pretty=format:%cd --date=format:%Y%m%d%H%m.%S -1 HEAD -- "$file")" -- "$file"
    else
      touch -d "$(git log --pretty=format:%cI -1 HEAD -- "$file")" -- "$file"
    fi
  fi
done
