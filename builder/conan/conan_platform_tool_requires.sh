#!/usr/bin/env sh
set -eu

# Detect installed build tools
# Append the output to the Conan profile to reuse already-installed tools

detect() {
  command="$1"
  regex="${2:-[^\s,]+$}"  # Default regex: last word of first line
  package="${3:-$command}"

  if command -v "$command" >/dev/null; then
    # bzip2 still tries to compress with --version, so we connect /dev/null to stdin
    if version=$("$command" --version 2>&1 </dev/null | grep --binary-files=text -Piom1 "$regex"); then
      echo "$package/$version";
    fi
  fi
}

echo '[platform_tool_requires]'
detect autoconf
detect automake
detect b2
detect bison
detect bzip2 '(?<=version )[^\s,]+'
detect cmake '(?<=version )[^\s,]+'
detect flex
detect gperf
detect m4
detect meson
detect ninja
detect pkgconf
