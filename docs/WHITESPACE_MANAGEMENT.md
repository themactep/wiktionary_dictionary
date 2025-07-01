# Whitespace Management

This repository includes automated tools to maintain clean code by removing trailing whitespace from all code files.

## Git Pre-commit Hook

A pre-commit hook is installed at `.git/hooks/pre-commit` that automatically:

- ✅ Scans all staged files for trailing whitespace
- ✅ Removes trailing spaces and tabs from code files
- ✅ Re-stages the cleaned files automatically
- ✅ Provides colored output showing what was fixed
- ✅ Never blocks commits (always exits with code 0)

### Supported File Types

The hook processes these file extensions:
- **Ruby**: `.rb`, `Rakefile`, `Gemfile`, `Guardfile`, `Capfile`, `.gemspec`
- **Web**: `.js`, `.ts`, `.css`, `.scss`, `.html`, `.erb`
- **Data**: `.yml`, `.yaml`, `.json`
- **Documentation**: `.md`, `.txt`

### Hook Output Example

```bash
Checking for trailing whitespace in staged files...
Removing trailing whitespace from: lib/example.rb
✓ Fixed trailing whitespace in: lib/example.rb
✓ Processed 15 files, fixed trailing whitespace in 1 files.
Modified files have been re-staged automatically.
```

## Manual Whitespace Cleanup

Use the manual script to clean up the entire repository:

```bash
# Dry run - see what would be fixed without making changes
./scripts/strip_whitespace.sh --dry-run

# Actually fix all files
./scripts/strip_whitespace.sh
```

### Script Features

- ✅ Scans entire repository recursively
- ✅ Excludes common directories (`.git`, `node_modules`, `vendor`, etc.)
- ✅ Processes same file types as git hook
- ✅ Provides detailed summary of changes
- ✅ Supports dry-run mode for safe preview

### Script Output Example

```bash
Running in dry-run mode (no files will be modified)
Scanning repository for files with trailing whitespace...
Would fix: lib/example.rb
Would fix: spec/example_spec.rb

=== Summary ===
Total files scanned: 156
Code files processed: 89
Files that would be fixed: 2
Run without --dry-run to actually fix the files.
```

## How It Works

### Pre-commit Hook Process

1. **File Detection**: Gets list of staged files from `git diff --cached --name-only`
2. **Extension Check**: Filters files by supported extensions
3. **Whitespace Detection**: Uses `grep -q '[[:space:]]$'` to find trailing whitespace
4. **Cleanup**: Uses `sed -i 's/[[:space:]]*$//'` to remove trailing whitespace
5. **Re-staging**: Automatically runs `git add` on modified files
6. **Reporting**: Shows colored output of all changes made

### Manual Script Process

1. **Repository Scan**: Uses `find . -type f` to get all files
2. **Directory Filtering**: Excludes `.git`, `node_modules`, `vendor`, etc.
3. **File Processing**: Same whitespace detection and cleanup as hook
4. **Backup Safety**: Creates temporary backups during processing
5. **Summary Report**: Shows total files scanned vs. files fixed

## Configuration

### Adding New File Types

Edit both files to add new extensions:

```bash
# In .git/hooks/pre-commit and scripts/strip_whitespace.sh
CODE_EXTENSIONS=(
    "rb"     # Ruby
    "py"     # Python (add this)
    "go"     # Go (add this)
    # ... existing extensions
)
```

### Excluding Directories

Add directories to exclude in the manual script:

```bash
EXCLUDE_DIRS=(
    ".git"
    "node_modules"
    "your_custom_dir"  # Add this
    # ... existing exclusions
)
```

## Troubleshooting

### Hook Not Running

If the pre-commit hook isn't running:

```bash
# Check if hook exists and is executable
ls -la .git/hooks/pre-commit

# Make it executable if needed
chmod +x .git/hooks/pre-commit

# Test the hook manually
.git/hooks/pre-commit
```

### Script Permission Issues

If the manual script won't run:

```bash
# Make script executable
chmod +x scripts/strip_whitespace.sh

# Run with bash explicitly
bash scripts/strip_whitespace.sh --dry-run
```

### Disabling the Hook Temporarily

To skip the hook for a specific commit:

```bash
git commit --no-verify -m "Commit message"
```

## Benefits

- **Consistent Code Style**: No trailing whitespace in any commits
- **Automatic Cleanup**: No manual intervention required
- **Safe Operation**: Never blocks commits, always allows them to proceed
- **Comprehensive Coverage**: Handles all common code file types
- **Visual Feedback**: Clear reporting of what was cleaned
- **Repository-wide Cleanup**: Manual script can clean entire codebase

## Integration with IDEs

Most IDEs can be configured to show/remove trailing whitespace:

- **VS Code**: `"files.trimTrailingWhitespace": true`
- **Vim**: `:set list` to show, `:%s/\s\+$//e` to remove
- **Sublime Text**: `"trim_trailing_white_space_on_save": true`
- **RubyMine**: Settings → Editor → General → Strip trailing spaces

The git hook provides a safety net even if IDE settings aren't configured.
