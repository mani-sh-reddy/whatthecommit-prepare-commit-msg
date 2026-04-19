#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <path_to_source_hook> <target_directory>"
  echo "Example: $0 ./my-pre-commit-script ~/projects"
  exit 1
fi

HOOK_SOURCE="$1"
TARGET_DIR="$2"
HOOK_NAME=$(basename "$HOOK_SOURCE")

# Validate inputs
if [ ! -f "$HOOK_SOURCE" ]; then
  echo "Error: Source hook file '$HOOK_SOURCE' does not exist."
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Target directory '$TARGET_DIR' does not exist."
  exit 1
fi

echo "Scanning '$TARGET_DIR' for Git repositories..."
echo "Copying hook: $HOOK_NAME"
echo "-------------------------------------------------------"

# Use find with -print0 to safely handle directory names with spaces
find "$TARGET_DIR" -type d -name ".git" -print0 | while IFS= read -r -d '' git_dir; do
  repo_path=$(dirname "$git_dir")
  repo_name=$(basename "$repo_path")
  hook_dest="$git_dir/hooks/$HOOK_NAME"

  # Ensure the .git/hooks directory exists (just in case)
  mkdir -p "$git_dir/hooks"

  # Print the repo name, formatted nicely for alignment
  printf "Repo: %-30s | " "$repo_name"

  if [ ! -f "$hook_dest" ]; then
    # Condition 1: File doesn't exist -> Add it
    cp "$HOOK_SOURCE" "$hook_dest"
    chmod +x "$hook_dest"
    echo "✅ Added newly"

  elif ! cmp -s "$HOOK_SOURCE" "$hook_dest"; then
    # Condition 2: File exists but is different -> Overwrite it
    cp "$HOOK_SOURCE" "$hook_dest"
    chmod +x "$hook_dest"
    echo "🔄 Updated (overwritten)"

  else
    # Condition 3: File exists and is identical -> Skip it
    echo "⏭️  Skipped (identical)"
  fi
done

echo "-------------------------------------------------------"
echo "Done!"
