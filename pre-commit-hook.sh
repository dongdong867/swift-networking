#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Pre-commit hook: fix, lint & format only staged Swift files, then re-add them to the index.
# - Uses `swiftlint --fix` for auto-fixes, then `swiftlint` for linting (per-file if available)
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

# Auto-fix staged files with swiftlint if available
fixed=0
if command -v swiftlint >/dev/null 2>&1; then
  echo "Running swiftlint --fix on staged Swift files..."
  
  for f in "${swift_files[@]}"; do
    if [ ! -f "$f" ]; then
      echo "⚠️  File not found: $f (skipping)"
      continue
    fi
    
    # Store file modification time before fix
    if [[ "$OSTYPE" == "darwin"* ]]; then
      before_mtime=$(stat -f "%m" "$f" 2>/dev/null || echo "0")
    else
      before_mtime=$(stat -c "%Y" "$f" 2>/dev/null || echo "0")
    fi
    
    # Run swiftlint --fix
    if swiftlint --fix "$f" >/dev/null 2>&1; then
      # Check if file was modified
      if [[ "$OSTYPE" == "darwin"* ]]; then
        after_mtime=$(stat -f "%m" "$f" 2>/dev/null || echo "0")
      else
        after_mtime=$(stat -c "%Y" "$f" 2>/dev/null || echo "0")
      fi
      
      if [ "$before_mtime" != "$after_mtime" ]; then
        fixed=1
      fi
    fi
  done
  
  # If any files were fixed, re-add them so the commit contains fixed code
  if [ "$fixed" -ne 0 ]; then
    echo "Re-adding auto-fixed files to the index..."
    git add -- "${swift_files[@]}"
  fi
  
  # Lint staged files with swiftlint. Use per-file lint to reduce runtime.
  echo "Running swiftlint lint on staged Swift files..."
  lint_failed=0
  for f in "${swift_files[@]}"; do
    # Run swiftlint on the specific file and capture its output so errors are printed to the console.
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
else
  echo "swiftlint not found; skipping auto-fix and linting."
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
