#!/usr/bin/env sh

set -eu

# cd to script directory
cd "$(dirname -- "$0")"

mkdir -p "$(conan config home)/profiles/"
cp ./conan_profile "$(conan config home)/profiles/default"

# Install dependencies with Conan for configurations used in CI

echo '==== Installing Release packages ===='
conan install ./ --build=missing \
  --lockfile=./conan-ci.lock \
  -s build_type=Release \
  -o "&:with_tests=True" \
  -o "&:with_benchmark=True" \
  "$@"

echo '==== Installing Debug packages ===='
conan install ./ --build=missing \
  --lockfile=./conan-ci.lock \
  -s build_type=Debug \
  -o "&:with_tests=True" \
  -o "&:with_benchmark=False" \
  "$@"

echo 'Cleaning cache'
# Remove old packages
conan remove '*' --lru 4w --confirm
# Remove download, source, build, temp; except binaries
conan cache clean
