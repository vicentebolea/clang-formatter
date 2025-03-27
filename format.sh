#!/bin/bash
set -eu

# Script to check or apply clang-format
# Usage: ./format.sh [--check] [--reformat] [file_pattern]

CHECK_ONLY=false
REFORMAT=false
FILE_PATTERN="*.cpp *.hpp *.c *.h"
EXCLUDE_PATTERN="build/ third_party/"

# Process arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --check)
      CHECK_ONLY=true
      shift
      ;;
    --reformat)
      REFORMAT=true
      shift
      ;;
    --exclude)
      EXCLUDE_PATTERN="$2"
      shift 2
      ;;
    *)
      FILE_PATTERN="$1"
      shift
      ;;
  esac
done

# For GitHub Actions integration, allow setting from environment
if [ "${REFORMAT:-false}" == "true" ]; then
  REFORMAT=true
fi

if [ "$CHECK_ONLY" = true ] && [ "$REFORMAT" = false ]; then
  # Keep CHECK_ONLY true only if not in reformat mode
  CHECK_ONLY=true
else
  # If reformat flag is true, we want to format regardless of check-only
  CHECK_ONLY=false
fi

# Find all matching files
FILES=$(find . -type f -name "*.cpp" -o -name "*.hpp" -o -name "*.c" -o -name "*.h" | grep -v "$EXCLUDE_PATTERN" || true)

if [ -z "$FILES" ]; then
  echo "No files to format"
  exit 0
fi

# Check if .clang-format exists
if [ ! -f ".clang-format" ]; then
  echo "Error: .clang-format file not found in repository root"
  exit 1
fi

if [ "$CHECK_ONLY" = true ]; then
  # Check format only
  echo "Checking format..."
  DIFF=0
  for FILE in $FILES; do
    FORMATTING_DIFF=$(clang-format --style=file "$FILE" | diff -u "$FILE" - || true)
    if [ -n "$FORMATTING_DIFF" ]; then
      echo "File $FILE needs formatting"
      echo "$FORMATTING_DIFF"
      DIFF=1
    fi
  done
  
  if [ $DIFF -eq 0 ]; then
    echo "✅ All files are properly formatted"
    exit 0
  else
    echo "❌ Some files need formatting. Run ./format.sh to fix."
    exit 1
  fi
else
  # Apply formatting
  echo "Applying clang-format to files..."
  for FILE in $FILES; do
    echo "Formatting $FILE"
    clang-format -i --style=file "$FILE"
  done
  echo "✅ Formatting complete"
  
  # If this is run in GitHub Actions with reformat flag, commit and push changes
  if [ "$REFORMAT" = true ] && [ -n "${GITHUB_HEAD_REF:-}" ]; then
    echo "Committing and pushing formatting changes..."
    git config --global user.name "GitHub Actions"
    git config --global user.email "actions@github.com"
    git add -u
    git commit -m "Apply clang-format [automated]" || echo "No changes to commit"
    
    # Only push if we actually committed changes
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse HEAD~1 2>/dev/null || echo 'initial')" ]; then
      git push origin HEAD:${GITHUB_HEAD_REF}
      echo "✅ Pushed formatting changes to PR branch"
    else
      echo "No changes to push"
    fi
  fi
fi