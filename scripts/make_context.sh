#!/bin/bash

cd "$(dirname "$0")/.." || exit 1

OUT="context.txt"
> "$OUT"

if [ -f pubspec.yaml ]; then
  echo "=== pubspec.yaml ===" >> "$OUT"
  cat pubspec.yaml >> "$OUT"
  echo >> "$OUT"
fi

find lib -type f -name "*.dart" | sort | while IFS= read -r file; do
  echo "=== $file ===" >> "$OUT"
  cat "$file" >> "$OUT"
  echo >> "$OUT"
done

echo "Готово: $OUT"