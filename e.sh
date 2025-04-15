#!/bin/bash

# Get all unstaged files
unstaged_files=$(git ls-files --modified --others --exclude-standard)

# Check if there are any unstaged files
if [ -z "$unstaged_files" ]; then
  echo "No unstaged files found."
  exit 0
fi

# Loop through each unstaged file
for file in $unstaged_files; do
  # Stage the file
  git add "$file"
  
  # Get just the filename without the path
  filename=$(basename "$file")
  
  # Commit with the specified message format
  git commit -m "docs: implement '$filename' documentation"
  
  echo "Committed: $file"
done

echo "All files have been staged and committed individually."