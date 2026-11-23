#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$repo/artifacts"
evidence=$(mktemp -d "$repo/artifacts/check.XXXXXXXX")
mkdir -p "$evidence/ui-captures"
printf 'Validation evidence: %s\n' "$evidence"
cmake -S "$repo" -B "$repo/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build "$repo/build" --parallel 4
MACANOS_QML_TEST_CAPTURES="$evidence/ui-captures" ctest --test-dir "$repo/build" -V
python3 "$repo/tests/test_processes.py" --build "$repo/build" --artifacts "$evidence/processes" --screenshots "$evidence/screenshots"
