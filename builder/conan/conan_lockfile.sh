#!/usr/bin/env sh
set -eu

# cd to script directory
cd "${0%/*}"

conan_everything_options='
  -o with_client=True
  -o with_tests=True
  -o with_benchmark=True
'
rm -f ./conan.lock

conan lockfile create ./ --update \
  --lockfile-out=./conan-rel.lock \
  -s build_type=Release \
  $conan_everything_options
conan lockfile create ./ --update \
  --lockfile-out=./conan-dbg.lock \
  -s build_type=Debug \
  $conan_everything_options

# Generates ./conan.lock
conan lock merge \
  --lockfile=./conan-rel.lock \
  --lockfile=./conan-dbg.lock
