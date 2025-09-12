#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Pre-commit hook: lint & format only staged Swift files, then re-add them to the index.
# - Uses `swiftlint` for linting (per-file if available)
# - Uses `swift-format` (if available) or `swiftformat` as a fallback for formatting

# Collect staged files (Added / Copied / Modified)
# Using a more compatible approach than mapfile
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

# Lint staged files with swiftlint if available. Use per-file lint to reduce runtime.
if command -v swiftlint >/dev/null 2>&1; then
  echo "Running swiftlint on staged Swift files..."
  lint_failed=0
  for f in "${swift_files[@]}"; do
    # Run swiftlint on the specific file and capture its output so errors are printed to the console.
    # Use --path to lint just the file and capture both stdout and stderr.
    if output="$(swiftlint lint "$f" 2>&1)"; then
      : # ok
    else
      echo "swiftlint reported issues in: $f"
      printf "%s\n" "$output"
      lint_failed=1
    fi
  done
  if [ "$lint_failed" -ne 0 ]; then
    echo "swiftlint reported issues. Fix them or stage changes before committing."
    exit 1
  fi
else
  echo "swiftlint not found; skipping linting."
fi

# Format staged files with available formatter
formatted=0
if command -v swift-format >/dev/null 2>&1; then
  echo "Formatting staged files with swift-format..."
  for f in "${swift_files[@]}"; do
    swift-format format --in-place "$f"
    exit_code=$?
    if [ "$exit_code" -eq 0 ]; then
      : # No changes made
    elif [ "$exit_code" -eq 1 ]; then
      formatted=1 # Changes were made
    else
      echo "swift-format failed on $f with exit code $exit_code"
      exit 1
    fi
  done
elif command -v swiftformat >/dev/null 2>&1; then
  echo "Formatting staged files with swiftformat..."
  if swiftformat "${swift_files[@]}"; then
    formatted=1
  else
    echo "swiftformat failed"; exit 1
  fi
else
  echo "No Swift formatter (swift-format or swiftformat) found; skipping formatting."
fi

# If any files were reformatted, re-add them so the commit contains formatted code
if [ "$formatted" -ne 0 ]; then
  echo "Re-adding reformatted files to the index..."
  git add -- "${swift_files[@]}"
fi

echo "Pre-commit checks passed for staged Swift files."
exit 0
