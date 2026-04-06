#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Pre-commit hook: fix, lint & format only staged Swift files, then re-add them to the index.
# - Uses `swiftlint --fix` for auto-fixes, then `swiftlint` for linting (per-file if available)
# - Uses `swift-format` (if available) or `swiftformat` as a fallback for formatting
#
# Strategy: record hashes BEFORE any tool runs, run all tools, then do ONE re-add at the end.
# This avoids intermediate git-add calls that would lose later tool changes (e.g. swiftlint
# removes a trailing comma, swift-format adds it back — a mid-run add would commit without it).

# Collect staged files (Added / Copied / Modified)
staged=()
while IFS= read -r -d '' file; do
  staged+=("$file")
done < <(git diff --cached --name-only --diff-filter=ACM -z)

if [ ${#staged[@]} -eq 0 ]; then
  echo "No staged files."
  exit 0
fi

# Filter to Swift files
swift_files=()
for f in "${staged[@]}"; do
  case "$f" in
    *.swift) swift_files+=("$f") ;;
  esac
done

if [ ${#swift_files[@]} -eq 0 ]; then
  echo "No staged Swift files to check."
  exit 0
fi

# Helper: content hash of a file (mtime is unreliable on fast SSDs)
file_hash() { md5 -q "$1" 2>/dev/null || shasum "$1" | awk '{print $1}'; }

# Helper: content hash of a file as it exists in the git index (staged version)
staged_hash() { git show ":$1" 2>/dev/null | md5 -q 2>/dev/null || git show ":$1" 2>/dev/null | shasum | awk '{print $1}'; }

# Step 1: Auto-fix with swiftlint
if command -v swiftlint >/dev/null 2>&1; then
  echo "Running swiftlint --fix on staged Swift files..."
  for f in "${swift_files[@]}"; do
    [ -f "$f" ] || { echo "[WARN]  File not found: $f (skipping)"; continue; }
    swiftlint --fix "$f" >/dev/null 2>&1 || true
  done
else
  echo "swiftlint not found; skipping auto-fix and linting."
fi

# Step 2: Format with swift-format or swiftformat
if command -v swift-format >/dev/null 2>&1; then
  echo "Formatting staged files with swift-format..."
  for f in "${swift_files[@]}"; do
    [ -f "$f" ] || { echo "[WARN]  File not found: $f (skipping)"; continue; }
    if ! swift-format format --in-place "$f" >/dev/null 2>&1; then
      echo "swift-format failed on $f"
      exit 1
    fi
  done
elif command -v swiftformat >/dev/null 2>&1; then
  echo "Formatting staged files with swiftformat..."
  for f in "${swift_files[@]}"; do
    [ -f "$f" ] || { echo "[WARN]  File not found: $f (skipping)"; continue; }
    if ! swiftformat "$f" >/dev/null 2>&1; then
      echo "swiftformat failed on $f"
      exit 1
    fi
  done
else
  echo "No Swift formatter (swift-format or swiftformat) found; skipping formatting."
fi

# Step 3: Lint (after all auto-fixes and formatting are done)
if command -v swiftlint >/dev/null 2>&1; then
  echo "Running swiftlint lint on staged Swift files..."
  lint_failed=0
  for f in "${swift_files[@]}"; do
    if output="$(swiftlint lint "$f" 2>&1)"; then
      : # ok
    else
      echo "swiftlint reported issues in: $f"
      printf "%s\n" "$output"
      lint_failed=1
    fi
  done
  if [ "$lint_failed" -ne 0 ]; then
    echo "swiftlint reported issues that cannot be auto-fixed. Fix them manually before committing."
    exit 1
  fi
fi

# Step 4: Re-add any files whose content changed vs the staged version
changed_files=()
for f in "${swift_files[@]}"; do
  [ -f "$f" ] || continue
  if [ "$(staged_hash "$f")" != "$(file_hash "$f")" ]; then
    changed_files+=("$f")
  fi
done

if [ ${#changed_files[@]} -ne 0 ]; then
  echo "Re-adding modified files to the index..."
  git add -- "${changed_files[@]}"
fi

echo "Pre-commit checks passed for staged Swift files."
exit 0
