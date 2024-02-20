#!/usr/bin/env sh

set -eu
concurrency_limit=${1:-}

if [ -n "$concurrency_limit" ]; then
  concurrency_option_conan="-c:a tools.build:jobs=$concurrency_limit"
fi

# Install dependencies with Conan for configurations used in pep/core/.gitlab-ci.yml

>>"${0%/*}/conan_profile" "${0%/*}/conan_platform_tool_requires.sh"
cp "${0%/*}/conan_profile" "$(conan config home)/profiles/default"

conan install ./ --build=missing --update \
  -s build_type=Release \
  $concurrency_option_conan \
  -o with_tests=True \
  -o with_benchmark=True \
  -o custom_dependency_opts=True
conan install ./ --build=missing \
  -s build_type=Debug \
  $concurrency_option_conan \
  -o with_tests=True \
  -o custom_dependency_opts=True
# Remove download, source, build, temp; except binaries
conan cache clean
