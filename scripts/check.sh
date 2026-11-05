#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cmake -S "$repo" -B "$repo/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build "$repo/build" --parallel 4
ctest --test-dir "$repo/build" --output-on-failure
python3 "$repo/tests/test_processes.py" --build "$repo/build" --artifacts "$repo/docs/test-results/processes" --screenshots "$repo/docs/screenshots"
