#!/usr/bin/env bash
set -eu -o pipefail

# Detect installed build tools
# Append the output to the Conan profile to reuse already-installed tools

echo '[platform_tool_requires]'
if ver=$(type autoconf 2>&1 >/dev/null && autoconf --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "autoconf/$ver"; fi
if ver=$(type automake 2>&1 >/dev/null && automake --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "automake/$ver"; fi
if ver=$(type b2       2>&1 >/dev/null && b2       --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "b2/$ver"; fi
if ver=$(type bison    2>&1 >/dev/null && bison    --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "bison/$ver"; fi
# bzip2 still tries to compress with --version
if ver=$(type bzip2    2>&1 >/dev/null && bzip2    --version 2>&1 </dev/null | grep --binary-files=text -Piom1 '(?<=version )[^\s,]+'); then echo "bzip2/$ver"; fi
if ver=$(type cmake    2>&1 >/dev/null && cmake    --version 2>&1 | grep -Piom1 '(?<=version )[^\s,]+'); then echo "cmake/$ver"; fi
if ver=$(type flex     2>&1 >/dev/null && flex     --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "flex/$ver"; fi
if ver=$(type gperf    2>&1 >/dev/null && gperf    --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "gperf/$ver"; fi
if ver=$(type m4       2>&1 >/dev/null && m4       --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "m4/$ver"; fi
if ver=$(type meson    2>&1 >/dev/null && meson    --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "meson/$ver"; fi
if ver=$(type ninja    2>&1 >/dev/null && ninja    --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "ninja/$ver"; fi
if ver=$(type pkgconf  2>&1 >/dev/null && pkgconf  --version 2>&1 | grep -Piom1 '[^\s,]+$'            ); then echo "pkgconf/$ver"; fi
