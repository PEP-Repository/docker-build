#!/usr/bin/env sh

# Restore the lockfile timestamps of local Conan recipes that did not change.
#
# The recipe revision of a package from our `local-recipes-index` remote is derived from the recipe
# contents, but its lockfile timestamp is the moment that revision was added to the local Conan
# cache, i.e. the moment the CI job ran. Regenerating the lockfile therefore always rewrites that
# timestamp, making the lockfile look changed even when the recipe itself is untouched.
#
# Copy the timestamp from a reference lockfile (normally the previously committed one) for every
# local recipe that resolved to the same revision, so that only genuine recipe changes update the
# entry.

set -eu

if [ $# -ne 2 ]; then
  >&2 echo "Usage: $0 <reference-lockfile> <target-lockfile>"
  exit 2
fi
reference="$1"
target="$2"

updated="$target.new"
trap 'rm -f "$updated"' EXIT

# `--indent 4` formats the way Conan does, so that only the timestamps differ from its output
jq --indent 4 --slurpfile reference "$reference" '
  # A lockfile entry is either a reference, or a [reference, package_ids] pair
  def entry_reference: if type == "string" then . else .[0] end;
  def with_entry_reference($replacement):
    if type == "string" then $replacement else [$replacement, .[1]] end;

  # The entry reference `name/version@user#revision%timestamp`, split around the `%`
  def revisioned: entry_reference | split("%")[0];
  def timestamp: entry_reference | split("%")[1];

  # Whether an entry is a local recipe, i.e. one whose user is `local`
  def is_local_recipe: revisioned | split("#")[0] | test("@local(/[^/]*)?$");

  def requires_keys: ["requires", "build_requires", "python_requires", "config_requires"];

  # The timestamps of the local recipes in the reference lockfile, by reference including revision
  ($reference[0] | [requires_keys[] as $key | (.[$key] // [])[]]
    | map(select(is_local_recipe and timestamp != null))
    | map({key: revisioned, value: timestamp})
    | from_entries) as $timestamps

  # Keep the reference timestamp for every local recipe that resolved to the same revision
  | def restore:
      $timestamps[revisioned] as $previous
      | if $previous == null or $previous == timestamp then .
        else
          ("Restoring timestamp of unchanged local recipe: \(revisioned)\n" | stderr | empty),
          with_entry_reference("\(revisioned)%\($previous)")
        end;
    reduce requires_keys[] as $key (.; if has($key) then .[$key] |= map(restore) else . end)
' "$target" >"$updated"

mv "$updated" "$target"
