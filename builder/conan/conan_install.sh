#!/usr/bin/env sh

set -eu
concurrency_limit=${1:-}

# cd to script directory
cd "${0%/*}"

if [ -n "$concurrency_limit" ]; then
  concurrency_option_conan="-c:a tools.build:jobs=$concurrency_limit"
else
  concurrency_option_conan=''
fi

# Install dependencies with Conan for configurations used in pep/core/.gitlab-ci.yml

>>"./conan_profile" "./conan_platform_tool_requires.sh"
mkdir -p "$(conan config home)/profiles/"
cp "./conan_profile" "$(conan config home)/profiles/default"

echo '==== Installing Release packages ===='
conan install ./ --build=missing --update \
  -s build_type=Release \
  $concurrency_option_conan \
  -o with_tests=True \
  -o with_benchmark=True \
  -o custom_dependency_opts=True

echo '==== Installing Debug packages ===='
conan install ./ --build=missing \
  -s build_type=Debug \
  $concurrency_option_conan \
  -o with_tests=True \
  -o custom_dependency_opts=True

echo 'Cleaning cache'
# Remove download, source, build, temp; except binaries
conan cache clean
