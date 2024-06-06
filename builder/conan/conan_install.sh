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

mkdir -p "$(conan config home)/profiles/"
cp ./conan_profile "$(conan config home)/profiles/default"

# Install dependencies with Conan for configurations used in pep/core/.gitlab-ci.yml

echo '==== Installing Release packages ===='
conan install ./ --build=missing \
  -s build_type=Release \
  $concurrency_option_conan \
  -o "&:with_client=False" \
  -o "&:with_tests=True" \
  -o "&:with_benchmark=True"

echo '==== Installing Debug packages ===='
conan install ./ --build=missing \
  -s build_type=Debug \
  $concurrency_option_conan \
  -o "&:with_client=False" \
  -o "&:with_tests=True" \
  -o "&:with_benchmark=False"

echo 'Cleaning cache'
# Remove old packages
conan remove '*' --lru 4w --confirm
# Remove download, source, build, temp; except binaries
conan cache clean
