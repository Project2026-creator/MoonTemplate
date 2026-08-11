#!/usr/bin/env bash
set -euo pipefail

iterations="${1:-10}"
if ! [[ "$iterations" =~ ^[1-9][0-9]*$ ]]; then
  echo "iterations must be a positive integer" >&2
  exit 2
fi

items='lexer, parser, engine, cli, tests, docs, release'
start_ns="$(date +%s%N)"
for ((i = 1; i <= iterations; i++)); do
  moon run src/cli --target native -- \
    --file examples/benchmark.txt \
    --var title="MoonBit" \
    --var enabled="true" \
    --var items="$items" \
    >/dev/null
done
end_ns="$(date +%s%N)"

total_ms=$(( (end_ns - start_ns) / 1000000 ))
average_ms=$(awk -v total="$total_ms" -v count="$iterations" 'BEGIN { printf "%.3f", total / count }')
printf 'benchmark=cli-native-file-render\niterations=%s\ntotal_ms=%s\naverage_ms=%s\n' \
  "$iterations" "$total_ms" "$average_ms"
