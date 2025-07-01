#!/bin/bash

# Script to strip trailing whitespace from all code files in the repository
# Usage: ./scripts/strip_whitespace.sh [--dry-run]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if this is a dry run
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${BLUE}Running in dry-run mode (no files will be modified)${NC}"
fi

# File extensions to process
CODE_EXTENSIONS=(
    "rb"     # Ruby
    "js"     # JavaScript
    "ts"     # TypeScript
    "css"    # CSS
    "scss"   # SCSS
    "html"   # HTML
    "erb"    # ERB templates
    "yml"    # YAML
    "yaml"   # YAML
    "json"   # JSON
    "md"     # Markdown
    "txt"    # Text files
    "rake"   # Rake files
    "gemspec" # Gemspec files
)

# Directories to exclude
EXCLUDE_DIRS=(
    ".git"
    "node_modules"
    "vendor"
    "tmp"
    "log"
    "coverage"
    ".bundle"
    "spec/vcr_cassettes"
)

# Function to check if directory should be excluded
should_exclude_dir() {
    local dir="$1"
    for exclude in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$dir" == *"$exclude"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if file extension should be processed
should_process_file() {
    local file="$1"
    local extension="${file##*.}"
    
    # Check if it's a special Ruby file without extension
    if [[ "$(basename "$file")" =~ ^(Rakefile|Gemfile|Guardfile|Capfile)$ ]]; then
        return 0
    fi
    
    # Check file extension
    for ext in "${CODE_EXTENSIONS[@]}"; do
        if [[ "$extension" == "$ext" ]]; then
            return 0
        fi
    done
    
    return 1
}

echo -e "${YELLOW}Scanning repository for files with trailing whitespace...${NC}"

files_with_whitespace=0
files_processed=0
total_files_scanned=0

# Find all files in the repository
while IFS= read -r -d '' file; do
    # Skip if file is in excluded directory
    if should_exclude_dir "$file"; then
        continue
    fi
    
    # Skip if not a regular file
    if [[ ! -f "$file" ]]; then
        continue
    fi
    
    total_files_scanned=$((total_files_scanned + 1))
    
    # Check if we should process this file
    if should_process_file "$file"; then
        files_processed=$((files_processed + 1))
        
        # Check if file has trailing whitespace
        if grep -q '[[:space:]]$' "$file"; then
            files_with_whitespace=$((files_with_whitespace + 1))
            
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "${YELLOW}Would fix: $file${NC}"
            else
                echo -e "${YELLOW}Fixing: $file${NC}"
                
                # Create backup
                cp "$file" "$file.backup"
                
                # Remove trailing whitespace
                sed -i 's/[[:space:]]*$//' "$file"
                
                # Check if file was actually modified
                if ! cmp -s "$file" "$file.backup"; then
                    echo -e "${GREEN}✓ Fixed trailing whitespace in: $file${NC}"
                else
                    echo -e "${BLUE}No changes needed for: $file${NC}"
                fi
                
                # Remove backup
                rm "$file.backup"
            fi
        fi
    fi
done < <(find . -type f -print0)

# Summary
echo -e "\n${BLUE}=== Summary ===${NC}"
echo -e "${BLUE}Total files scanned: $total_files_scanned${NC}"
echo -e "${BLUE}Code files processed: $files_processed${NC}"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Files that would be fixed: $files_with_whitespace${NC}"
    if [[ $files_with_whitespace -gt 0 ]]; then
        echo -e "${YELLOW}Run without --dry-run to actually fix the files.${NC}"
    fi
else
    echo -e "${GREEN}Files with trailing whitespace fixed: $files_with_whitespace${NC}"
fi

if [[ $files_with_whitespace -eq 0 ]]; then
    echo -e "${GREEN}✓ No trailing whitespace found!${NC}"
fi
