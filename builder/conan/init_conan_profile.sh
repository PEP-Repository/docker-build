#!/usr/bin/env bash
set -eu -o pipefail

# You can override the Conan profile name by passing it as the first parameter
profile_name="${1:-default}"

conan_home="$(conan config home)"
conan_profiles_dir="$conan_home/profiles"
mkdir -p "$conan_profiles_dir"
conan_profile="$conan_profiles_dir/$profile_name"

if [ -e "$conan_profile" ]; then
  read -rp "$conan_profile already exists, replace? (y/n): " choice
  case $choice in
    [Yy]* ) ;;
    * )
      echo Aborting
      exit 1;;
  esac
fi

# Render our autodetect profile
conan profile show --profile:all="$(dirname -- "$0")/conan_profile" --context host |
  tee "$conan_profile"
echo "Profile written to $conan_profile"
