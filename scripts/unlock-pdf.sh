#!/usr/bin/env bash
set -euo pipefail

if ! command -v qpdf >/dev/null 2>&1; then
  echo "Error: qpdf is not installed. Run: brew install qpdf" >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <file1.pdf> [file2.pdf ...]" >&2
  exit 1
fi

for input in "$@"; do
  if [ ! -f "$input" ]; then
    echo "Skipping (not a file): $input" >&2
    continue
  fi

  dir=$(dirname "$input")
  base=$(basename "$input" .pdf)
  output="$dir/$base-unlocked.pdf"

  if qpdf --warning-exit-0 --decrypt "$input" "$output" 2>/dev/null; then
    echo "Unlocked: $output"
  else
    read -r -s -p "Password for $(basename "$input"): " password
    echo
    if qpdf --warning-exit-0 --password="$password" --decrypt "$input" "$output"; then
      echo "Unlocked: $output"
    else
      echo "Failed to unlock: $input" >&2
      rm -f "$output"
    fi
  fi
done
