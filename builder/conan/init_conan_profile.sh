#!/usr/bin/env bash
set -eu -o pipefail

# You can override the Conan profile name by passing it as the first parameter
profile_name="${1:-default}"

conan_home="$(conan config home)"
conan_profile="$conan_home/profiles/$profile_name"

if [ -e "$conan_profile" ]; then
  read -rp "$conan_profile already exists, replace? (y/n): " choice
  case $choice in
    [Yy]* ) ;;
    * )
      echo Aborting
      exit 1;;
  esac
fi

# Render our autodetect profile and take one section ('Build profile:') to put in the profile file (and print)
conan profile show --profile:all="$(dirname -- "$0")/conan_profile" |
  awk 'p==1 {print $0} /Build profile:/ {p=1}' |
  tee "$conan_profile"
echo "Profile written to $conan_profile"
