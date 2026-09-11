#!/usr/bin/env python3

"""Restore the lockfile timestamps of local Conan recipes that did not change.

The recipe revision of a package from our `local-recipes-index` remote is derived from the recipe
contents, but its lockfile timestamp is the moment that revision was added to the local Conan
cache, i.e. the moment the CI job ran. Regenerating the lockfile therefore always rewrites that
timestamp, making the lockfile look changed even when the recipe itself is untouched.

Copy the timestamp from a reference lockfile (normally the previously committed one) for every
local recipe that resolved to the same revision, so that only genuine recipe changes update the
entry.
"""

import json
import sys
from pathlib import Path
from typing import Any

# A lockfile entry is either a reference, or a [reference, package_ids] pair
Entry = str | list[Any]
# A lockfile as parsed from JSON, mapping e.g. `requires` to its entries
Lockfile = dict[str, Any]
# Timestamps by reference including revision
Timestamps = dict[str, str]

LOCAL_RECIPE_USER = 'local'
REQUIRES_KEYS = ('requires', 'build_requires', 'python_requires', 'config_requires')


def split_timestamp(reference: str) -> tuple[str, str | None]:
    """Split `name/version@user#revision%timestamp` into the reference and the timestamp."""
    revisioned, separator, timestamp = reference.rpartition('%')
    return (revisioned, timestamp) if separator else (reference, None)


def is_local_recipe(revisioned: str) -> bool:
    """Whether `name/version@user#revision` is a local recipe, i.e. has user `local`."""
    user_channel = revisioned.partition('#')[0].partition('@')[2]
    return user_channel.partition('/')[0] == LOCAL_RECIPE_USER


def entry_reference(entry: Entry) -> str:
    """Get the reference of a lockfile entry, which is either that reference or a
    [reference, package_ids] pair."""
    return entry if isinstance(entry, str) else entry[0]


def with_reference(entry: Entry, reference: str) -> Entry:
    """Copy a lockfile entry, replacing its reference."""
    return reference if isinstance(entry, str) else [reference, entry[1]]


def load_lockfile(path: Path) -> Lockfile:
    with path.open(encoding='utf-8') as file:
        lockfile: Lockfile = json.load(file)
    return lockfile


def local_recipe_timestamps(lockfile: Lockfile) -> Timestamps:
    """Map the revisioned references of the local recipes in a lockfile to their timestamps."""
    timestamps: Timestamps = {}
    for key in REQUIRES_KEYS:
        for entry in lockfile.get(key, []):
            revisioned, timestamp = split_timestamp(entry_reference(entry))
            if timestamp is not None and is_local_recipe(revisioned):
                timestamps[revisioned] = timestamp
    return timestamps


def restore_timestamps(lockfile: Lockfile, timestamps: Timestamps) -> bool:
    """Replace the timestamps of the local recipes in a lockfile by the ones in `timestamps`,
    matching on the reference including the revision. Returns whether anything changed."""
    changed = False
    for key in REQUIRES_KEYS:
        entries: list[Entry] = lockfile.get(key, [])
        for index, entry in enumerate(entries):
            revisioned, timestamp = split_timestamp(entry_reference(entry))
            previous = timestamps.get(revisioned)
            if previous is None or previous == timestamp:
                continue
            entries[index] = with_reference(entry, f'{revisioned}%{previous}')
            changed = True
            print(f'Restoring timestamp of unchanged local recipe: {revisioned}')
    return changed


def main(argv: list[str]) -> None:
    if len(argv) != 3:
        sys.exit(f'Usage: {argv[0]} <reference-lockfile> <target-lockfile>')
    reference_path, target_path = Path(argv[1]), Path(argv[2])

    target = load_lockfile(target_path)
    if not restore_timestamps(target, local_recipe_timestamps(load_lockfile(reference_path))):
        print('No local recipe timestamps to restore')
        return

    with target_path.open('w', encoding='utf-8') as file:
        # Write the way Conan does, so that only the timestamps differ from what it produced
        json.dump(target, file, indent=4)
        file.write('\n')


if __name__ == '__main__':
    main(sys.argv)
